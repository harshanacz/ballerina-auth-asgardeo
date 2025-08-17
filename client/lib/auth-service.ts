// Authentication service client for Next.js
export interface UserInfo {
  sub: string;
  email?: string;
  given_name?: string;
  family_name?: string;
  name?: string;
  picture?: string;
}

export interface AuthTokens {
  access_token: string;
  id_token?: string;
  refresh_token?: string;
  user_info: UserInfo;
}

export interface TokenValidationResponse {
  valid: boolean;
  payload?: any;
  error?: string;
}

class AuthService {
  private baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:8080') {
    this.baseUrl = baseUrl;
  }

  /**
   * Get the authorization URL for Asgardeo login
   */
  async getAuthorizationUrl(): Promise<{ authUrl: string }> {
    const response = await fetch(`${this.baseUrl}/auth/authorize`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to get authorization URL: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Exchange authorization code for tokens
   */
  async exchangeCodeForTokens(code: string, state?: string): Promise<AuthTokens> {
    const response = await fetch(`${this.baseUrl}/auth/callback`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ code, state }),
    });

    if (!response.ok) {
      throw new Error(`Token exchange failed: ${response.statusText}`);
    }

    const tokenData = await response.json();
    
    // Extract user info from ID token if available
    let userInfo: UserInfo = { sub: '' };
    
    if (tokenData.id_token) {
      try {
        // Decode the ID token (just the payload part, without verification)
        const base64Payload = tokenData.id_token.split('.')[1];
        const payload = JSON.parse(atob(base64Payload));
        
        userInfo = {
          sub: payload.sub || '',
          email: payload.email,
          given_name: payload.given_name,
          family_name: payload.family_name,
          name: payload.name,
          picture: payload.picture
        };
      } catch (error) {
        console.warn('Failed to decode ID token:', error);
        userInfo = { sub: 'unknown' };
      }
    }

    return {
      access_token: tokenData.access_token,
      id_token: tokenData.id_token,
      refresh_token: tokenData.refresh_token,
      user_info: userInfo
    };
  }

  /**
   * Validate a JWT token
   */
  async validateToken(token: string): Promise<TokenValidationResponse> {
    const response = await fetch(`${this.baseUrl}/auth/validate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ token }),
    });

    if (!response.ok) {
      throw new Error(`Token validation failed: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshToken(refreshToken: string): Promise<AuthTokens> {
    const response = await fetch(`${this.baseUrl}/auth/refresh`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (!response.ok) {
      throw new Error(`Token refresh failed: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Logout user
   */
  async logout(accessToken?: string): Promise<{ message: string }> {
    const response = await fetch(`${this.baseUrl}/auth/logout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ access_token: accessToken }),
    });

    if (!response.ok) {
      throw new Error(`Logout failed: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Redirect to Asgardeo login
   */
  async redirectToLogin(): Promise<void> {
    try {
      const { authUrl } = await this.getAuthorizationUrl();
      window.location.href = authUrl;
    } catch (error) {
      console.error('Failed to redirect to login:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const authService = new AuthService();
export default AuthService;
