export interface AuthTokenPayload {
  sub: string;
  email: string;
  displayName?: string | null;
  iat?: number;
  exp?: number;
}

export interface AuthUser {
  id: string;
  email: string;
  displayName?: string | null;
}