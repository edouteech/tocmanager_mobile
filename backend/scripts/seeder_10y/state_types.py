from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Set, Tuple

from scripts.seeder_10y.catalog_data import BoutiqueBlueprint


@dataclass
class StaffSeedRef:
    id: str
    username: str
    full_name: str
    role: str
    magasin_index: int
    is_active: bool


@dataclass
class ProductSeedRef:
    sync_id: str
    name: str
    price: float
    cost_price: float
    custom_prices: Dict[str, float]
    available_magasins: Set[str]


@dataclass
class BoutiqueSeedState:
    blueprint: BoutiqueBlueprint
    boutique_id: str
    start_at: datetime
    end_at: datetime
    magasin_ids: List[str]
    pos_magasin_ids: List[str]
    warehouse_magasin_ids: List[str]
    staff: List[StaffSeedRef]
    products: List[ProductSeedRef]
    client_ids: List[Tuple[str, str]]
    supplier_ids: List[Tuple[str, str]]
    client_balances: Dict[str, float]
    supplier_balances: Dict[str, float]
    stock_qty: Dict[Tuple[str, str], float]
    product_names: Dict[str, str]
