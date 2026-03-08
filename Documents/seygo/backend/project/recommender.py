from __future__ import annotations

from pathlib import Path
from typing import Union

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MinMaxScaler


class PlaceRecommender:
    """
    Content-based place recommender using:
    - category + tags text similarity (TF-IDF + cosine similarity)
    - rating as an additional quality signal
    """

    REQUIRED_COLUMNS = [
        "id",
        "name",
        "category",
        "rating",
        "latitude",
        "longitude",
        "tags",
    ]

    def __init__(self, csv_path: Union[str, Path]) -> None:
        self.csv_path = Path(csv_path)
        self.df = self._load_and_prepare_data(self.csv_path)

        # Build text feature per place.
        self.df["feature_text"] = (
            self.df["category"].astype(str).str.lower().str.strip()
            + " "
            + self.df["tags"].astype(str).str.lower().str.replace(";", " ", regex=False)
        )

        # Encode category + tags with TF-IDF.
        self.vectorizer = TfidfVectorizer(stop_words="english")
        self.text_matrix = self.vectorizer.fit_transform(self.df["feature_text"])

        # Normalize rating so it can be blended with similarity scores.
        self.scaler = MinMaxScaler()
        self.df["rating_norm"] = self.scaler.fit_transform(self.df[["rating"]])

        # Place-to-place similarity matrix (cosine).
        self.similarity_matrix = cosine_similarity(self.text_matrix)

    def _load_and_prepare_data(self, csv_path: Path) -> pd.DataFrame:
        df = pd.read_csv(csv_path)
        missing = [c for c in self.REQUIRED_COLUMNS if c not in df.columns]
        if missing:
            raise ValueError(f"Missing required columns: {missing}")

        # Keep required columns and drop rows without key recommendation data.
        df = df[self.REQUIRED_COLUMNS].copy()
        df = df.dropna(subset=["name", "category", "tags", "rating"])
        df["name"] = df["name"].astype(str).str.strip()
        df["category"] = df["category"].astype(str).str.strip()
        df["tags"] = df["tags"].astype(str).str.strip()
        df["rating"] = pd.to_numeric(df["rating"], errors="coerce")
        df = df.dropna(subset=["rating"])
        return df.reset_index(drop=True)

    def recommend_places(self, query: str, top_n: int = 5) -> pd.DataFrame:
        """
        Recommend places from:
        1) a place name (e.g., "Sigiriya Rock Fortress")
        2) an interest keyword (e.g., "waterfall")
        """
        query = query.strip().lower()
        if not query:
            raise ValueError("Query cannot be empty.")

        # If query matches a place name, use place-to-place similarity row.
        name_matches = self.df[self.df["name"].str.lower() == query]
        if not name_matches.empty:
            place_idx = int(name_matches.index[0])
            content_scores = self.similarity_matrix[place_idx].copy()
            content_scores[place_idx] = -1.0  # Exclude the same place.
        else:
            # Otherwise, treat query as user interest and compare against all places.
            query_vec = self.vectorizer.transform([query])
            content_scores = cosine_similarity(query_vec, self.text_matrix).flatten()

        # Blend content score with normalized rating.
        # Weights can be tuned later based on app feedback.
        final_scores = (0.85 * content_scores) + (0.15 * self.df["rating_norm"].values)
        top_indices = np.argsort(final_scores)[::-1][:top_n]

        result = self.df.loc[top_indices, ["id", "name", "category", "rating", "tags"]].copy()
        result["score"] = final_scores[top_indices]
        return result.reset_index(drop=True)


def recommend_places(query: str, top_n: int = 5) -> pd.DataFrame:
    """
    Convenience function requested in the prompt.
    Example:
        recommend_places("waterfall")
    """
    csv_file = Path(__file__).with_name("places.csv")
    recommender = PlaceRecommender(csv_file)
    return recommender.recommend_places(query=query, top_n=top_n)


if __name__ == "__main__":
    print("Interest-based recommendations for 'waterfall':")
    print(recommend_places("waterfall"), end="\n\n")

    print("Place-based recommendations for 'Unawatuna Beach':")
    recommender = PlaceRecommender(Path(__file__).with_name("places.csv"))
    print(recommender.recommend_places("Unawatuna Beach"))
