'use client';

import { useAuth, withAuth } from '../../lib/auth-context';

function Dashboard() {
  const { user, logout } = useAuth();

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white shadow rounded-lg">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
              <button
                onClick={handleLogout}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md transition-colors"
              >
                Logout
              </button>
            </div>
          </div>
          
          <div className="p-6">
            <div className="mb-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Welcome!</h2>
              <p className="text-gray-600">
                You have successfully authenticated with Asgardeo using Ballerina.
              </p>
            </div>

            {user && (
              <div className="bg-gray-50 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">User Information</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">Subject ID</label>
                    <p className="mt-1 text-sm text-gray-900">{user.sub}</p>
                  </div>
                  
                  {user.email && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Email</label>
                      <p className="mt-1 text-sm text-gray-900">{user.email}</p>
                    </div>
                  )}
                  
                  {user.name && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Full Name</label>
                      <p className="mt-1 text-sm text-gray-900">{user.name}</p>
                    </div>
                  )}
                  
                  {user.given_name && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Given Name</label>
                      <p className="mt-1 text-sm text-gray-900">{user.given_name}</p>
                    </div>
                  )}
                  
                  {user.family_name && (
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Family Name</label>
                      <p className="mt-1 text-sm text-gray-900">{user.family_name}</p>
                    </div>
                  )}
                </div>
                
                {user.picture && (
                  <div className="mt-4">
                    <label className="block text-sm font-medium text-gray-700 mb-2">Profile Picture</label>
                    <img
                      src={user.picture}
                      alt="Profile"
                      className="w-16 h-16 rounded-full"
                    />
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default withAuth(Dashboard);
