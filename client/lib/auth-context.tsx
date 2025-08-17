'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { authService, AuthTokens, UserInfo } from './auth-service';

interface AuthContextType {
  user: UserInfo | null;
  tokens: AuthTokens | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: () => Promise<void>;
  logout: () => Promise<void>;
  refreshTokens: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserInfo | null>(null);
  const [tokens, setTokens] = useState<AuthTokens | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isAuthenticated = !!user && !!tokens;

  // Load stored tokens on initialization
  useEffect(() => {
    const loadStoredTokens = () => {
      try {
        const storedTokens = localStorage.getItem('authTokens');
        const storedUser = localStorage.getItem('user');
        
        if (storedTokens && storedUser) {
          setTokens(JSON.parse(storedTokens));
          setUser(JSON.parse(storedUser));
        }
      } catch (error) {
        console.error('Failed to load stored tokens:', error);
        // Clear invalid stored data
        localStorage.removeItem('authTokens');
        localStorage.removeItem('user');
      } finally {
        setIsLoading(false);
      }
    };

    loadStoredTokens();
  }, []);

  // Handle OAuth callback
  useEffect(() => {
    const handleOAuthCallback = async () => {
      const urlParams = new URLSearchParams(window.location.search);
      const code = urlParams.get('code');
      const state = urlParams.get('state');
      const error = urlParams.get('error');

      if (error) {
        console.error('OAuth error:', error);
        setIsLoading(false);
        return;
      }

      if (code) {
        try {
          const authTokens = await authService.exchangeCodeForTokens(code, state || undefined);
          setTokens(authTokens);
          setUser(authTokens.user_info);
          
          // Store tokens securely
          localStorage.setItem('authTokens', JSON.stringify(authTokens));
          localStorage.setItem('user', JSON.stringify(authTokens.user_info));
          
          // Clean up URL
          window.history.replaceState({}, document.title, window.location.pathname);
        } catch (error) {
          console.error('Token exchange failed:', error);
        } finally {
          setIsLoading(false);
        }
      } else {
        // No code parameter, just stop loading
        setIsLoading(false);
      }
    };

    if (isLoading) {
      handleOAuthCallback();
    }
  }, [isLoading]);

  const login = async (): Promise<void> => {
    try {
      await authService.redirectToLogin();
    } catch (error) {
      console.error('Login failed:', error);
      throw error;
    }
  };

  const logout = async (): Promise<void> => {
    try {
      if (tokens?.access_token) {
        await authService.logout(tokens.access_token);
      }
    } catch (error) {
      console.error('Logout request failed:', error);
      // Continue with local logout even if server logout fails
    } finally {
      // Clear local state
      setUser(null);
      setTokens(null);
      localStorage.removeItem('authTokens');
      localStorage.removeItem('user');
    }
  };

  const refreshTokens = async (): Promise<void> => {
    if (!tokens?.refresh_token) {
      throw new Error('No refresh token available');
    }

    try {
      const newTokens = await authService.refreshToken(tokens.refresh_token);
      setTokens(newTokens);
      setUser(newTokens.user_info);
      
      // Update stored tokens
      localStorage.setItem('authTokens', JSON.stringify(newTokens));
      localStorage.setItem('user', JSON.stringify(newTokens.user_info));
    } catch (error) {
      console.error('Token refresh failed:', error);
      // If refresh fails, clear tokens and redirect to login
      await logout();
      throw error;
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        tokens,
        isLoading,
        isAuthenticated,
        login,
        logout,
        refreshTokens,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

// Higher-order component for protected routes
export function withAuth<P extends object>(Component: React.ComponentType<P>) {
  return function AuthenticatedComponent(props: P) {
    const { isAuthenticated, isLoading, login } = useAuth();

    if (isLoading) {
      return (
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 mx-auto mb-4"></div>
            <p>Loading...</p>
          </div>
        </div>
      );
    }

    if (!isAuthenticated) {
      return (
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-center">
            <h1 className="text-2xl font-bold mb-4">Authentication Required</h1>
            <p className="mb-6">Please log in to access this page.</p>
            <button
              onClick={login}
              className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition-colors"
            >
              Login with Asgardeo
            </button>
          </div>
        </div>
      );
    }

    return <Component {...props} />;
  };
}
