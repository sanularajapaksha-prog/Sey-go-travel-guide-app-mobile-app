from typing import Optional


PLACE_TAXONOMY: dict[str, list[str]] = {
    'Nature & Outdoor': [
        'Beaches',
        'Waterfalls',
        'Mountains / Hiking trails',
        'National parks',
        'Forest reserves',
        'Lakes & rivers',
        'Viewpoints / scenic spots',
        'Camping sites',
    ],
    'Cultural & Heritage': [
        'Historical sites',
        'Ancient cities',
        'Temples / churches / mosques',
        'Museums',
        'Archaeological sites',
        'Cultural villages',
        'Heritage landmarks',
    ],
    'City & Urban Experiences': [
        'City centers',
        'Markets / bazaars',
        'Street food areas',
        'Shopping districts',
        'Nightlife spots',
        'Rooftop views',
    ],
    'Adventure & Activities': [
        'Surfing spots',
        'Diving / snorkeling',
        'Wildlife safaris',
        'Rock climbing',
        'Zip lining',
        'Cycling routes',
        'Boat tours',
    ],
    'Food & Dining': [
        'Local restaurants',
        'Cafes',
        'Street food spots',
        'Food markets',
        'Fine dining',
        'Food experiences (cooking classes)',
    ],
    'Relaxation & Wellness': [
        'Spas',
        'Hot springs',
        'Yoga retreats',
        'Quiet retreats',
        'Resorts',
    ],
    'Wildlife & Nature Experiences': [
        'Zoos',
        'Bird watching spots',
        'Elephant sanctuaries',
        'Marine parks',
        'Turtle hatcheries',
    ],
    'Events & Entertainment': [
        'Festivals',
        'Live music venues',
        'Cultural shows',
        'Theme parks',
        'Cinemas',
    ],
    'Hidden Gems (great for Seygo)': [
        'Secret viewpoints',
        'Local hangout spots',
        'Unknown waterfalls',
        'Small villages',
        'Off-the-beaten-path locations',
    ],
}

_CATEGORY_KEYWORDS: dict[str, list[str]] = {
    'Beaches': ['beach', 'coast', 'shore', 'bay'],
    'Waterfalls': ['waterfall', 'falls', 'cascade'],
    'Mountains / Hiking trails': ['mountain', 'hiking', 'trail', 'peak', 'ella rock'],
    'National parks': ['national park', 'park'],
    'Forest reserves': ['forest reserve', 'rainforest', 'jungle', 'forest'],
    'Lakes & rivers': ['lake', 'river', 'lagoon', 'reservoir'],
    'Viewpoints / scenic spots': ['viewpoint', 'scenic', 'lookout', 'sunset point'],
    'Camping sites': ['camping', 'camp site', 'campground'],
    'Historical sites': ['historical', 'historic', 'fort'],
    'Ancient cities': ['ancient city', 'ruins', 'kingdom'],
    'Temples / churches / mosques': ['temple', 'church', 'mosque', 'kovil'],
    'Museums': ['museum'],
    'Archaeological sites': ['archaeological', 'excavation', 'stupa'],
    'Cultural villages': ['cultural village', 'village tour'],
    'Heritage landmarks': ['heritage', 'landmark', 'unesco'],
    'City centers': ['city center', 'downtown', 'town'],
    'Markets / bazaars': ['market', 'bazaar'],
    'Street food areas': ['street food', 'hawker'],
    'Shopping districts': ['shopping', 'mall', 'district'],
    'Nightlife spots': ['nightlife', 'club', 'bar', 'pub'],
    'Rooftop views': ['rooftop'],
    'Surfing spots': ['surf', 'surfing'],
    'Diving / snorkeling': ['diving', 'snorkeling', 'snorkelling'],
    'Wildlife safaris': ['safari', 'wildlife', 'game drive'],
    'Rock climbing': ['rock climbing', 'climbing'],
    'Zip lining': ['zip line', 'ziplining'],
    'Cycling routes': ['cycling', 'bike route'],
    'Boat tours': ['boat', 'boat tour', 'cruise'],
    'Local restaurants': ['restaurant', 'eatery'],
    'Cafes': ['cafe', 'coffee'],
    'Street food spots': ['street food'],
    'Food markets': ['food market'],
    'Fine dining': ['fine dining'],
    'Food experiences (cooking classes)': ['cooking class', 'culinary'],
    'Spas': ['spa', 'massage'],
    'Hot springs': ['hot spring'],
    'Yoga retreats': ['yoga retreat', 'yoga'],
    'Quiet retreats': ['quiet retreat', 'retreat'],
    'Resorts': ['resort'],
    'Zoos': ['zoo'],
    'Bird watching spots': ['bird watching', 'bird sanctuary'],
    'Elephant sanctuaries': ['elephant sanctuary'],
    'Marine parks': ['marine park', 'coral'],
    'Turtle hatcheries': ['turtle hatchery', 'turtle'],
    'Festivals': ['festival'],
    'Live music venues': ['live music', 'music venue'],
    'Cultural shows': ['cultural show', 'dance show'],
    'Theme parks': ['theme park', 'water park'],
    'Cinemas': ['cinema', 'movie theater', 'theatre'],
    'Secret viewpoints': ['secret viewpoint', 'hidden viewpoint'],
    'Local hangout spots': ['hangout', 'local spot'],
    'Unknown waterfalls': ['unknown waterfall', 'hidden waterfall'],
    'Small villages': ['small village', 'village'],
    'Off-the-beaten-path locations': ['off-the-beaten-path', 'offbeat', 'hidden gem'],
}


def all_categories() -> list[str]:
    return [category for categories in PLACE_TAXONOMY.values() for category in categories]


def infer_taxonomy(
    name: str,
    category: str,
    tags: list[str],
    description: Optional[str],
) -> tuple[str, str]:
    text = ' '.join([name, category, description or '', *tags]).lower()

    for taxonomy_category, keywords in _CATEGORY_KEYWORDS.items():
        if any(keyword in text for keyword in keywords):
            return taxonomy_category, _group_for_category(taxonomy_category)

    return 'Viewpoints / scenic spots', 'Nature & Outdoor'


def _group_for_category(taxonomy_category: str) -> str:
    for group, categories in PLACE_TAXONOMY.items():
        if taxonomy_category in categories:
            return group
    return 'Nature & Outdoor'


def normalize_category_name(value: str) -> str:
    text = value.strip().lower()
    for category in all_categories():
        if category.lower() == text:
            return category
    return value.strip()
