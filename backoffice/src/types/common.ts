export interface PaginatedResponse<T, S = Record<string, number>> {
  items: T[];
  total: number;
  page: number;
  pages: number;
  limit: number;
  summary?: S;
}
