# 🔐 Ballerina Authentication with Asgardeo & Supabase

[![Ballerina](https://img.shields.io/badge/Ballerina-2201.10.2-blue)](https://ballerina.io/)
[![Next.js](https://img.shields.io/badge/Next.js-15.4.6-black)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green)](https://supabase.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern fullstack authentication application demonstrating OAuth2 integration between Ballerina backend services, Asgardeo (WSO2 Identity Server), and Supabase database with a Next.js frontend.

## 🚀 Features

- ✅ **OAuth2 Authorization Code Flow** with Asgardeo
- ✅ **JWT Token Management** (Access, ID, Refresh tokens)
- ✅ **User Data Persistence** with Supabase PostgreSQL
- ✅ **Secure Token Storage** with automatic refresh
- ✅ **Protected Routes** using Higher-Order Components
- ✅ **User Profile Management** with database persistence
- ✅ **CORS Enabled** for cross-origin requests
- ✅ **TypeScript Support** for type safety
- ✅ **Responsive UI** with Tailwind CSS

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Next.js App   │◄──►│ Ballerina Service │◄──►│    Asgardeo     │
│   (Port 3000)   │    │   (Port 8080)     │    │  Identity Server │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │    Supabase     │
                        │   PostgreSQL    │
                        └─────────────────┘
```

### Components

- **Frontend**: Next.js 15 with React 19, TypeScript, and Tailwind CSS
- **Backend**: Ballerina authentication service with RESTful APIs
- **Identity Provider**: Asgardeo (WSO2 Identity Server)
- **Database**: Supabase PostgreSQL for user data persistence
- **Authentication Flow**: OAuth2 Authorization Code with user data synchronization

## 📋 Prerequisites

- **[Ballerina](https://ballerina.io/downloads/)** v2201.10.2 or later
- **[Node.js](https://nodejs.org/)** v18.0.0 or later
- **[Asgardeo Account](https://asgardeo.io/)** with an application configured
- **[Supabase Account](https://supabase.com/)** with a project set up

## ⚙️ Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd ballerina-apigateway-v5
```

### 2. Configure Asgardeo

1. Login to [Asgardeo Console](https://console.asgardeo.io)
2. Create a new application or use an existing one
3. Configure the following settings:
   - **Redirect URI**: `http://localhost:3000/dashboard`
   - **Allowed Grant Types**: Authorization Code
   - **Allowed Scopes**: `openid`, `profile`

### 3. Configure the Ballerina Service

1. Copy the configuration template:
   ```bash
   cd bal-backend
   cp Config.toml.template Config.toml
   ```

2. Edit `Config.toml` with your Asgardeo credentials:
   ```toml
   [auth_service]
   asgardeoClientId = "YOUR_CLIENT_ID"
   asgardeoClientSecret = "YOUR_CLIENT_SECRET"
   asgardeoRedirectUri = "http://localhost:3000/dashboard"
   asgardeoBaseUrl = "https://api.asgardeo.io/t/YOUR_ORGANIZATION/oauth2"
   asgardeoScope = "openid profile"
   serverPort = 8080
   ```

### 4. Install Dependencies

```bash
# Install root dependencies (for convenience scripts)
npm install

# Install client dependencies
npm run install:client
```

## 🚦 Running the Application

### Option 1: Run Both Services Together (Recommended)

```bash
npm start
```

This will start both the Ballerina service and Next.js app concurrently.

### Option 2: Run Services Separately

**Terminal 1 - Start Ballerina Service:**
```bash
cd bal-backend; bal run
```

**Terminal 2 - Start Next.js App:**
```bash
cd client
npm run dev
```

### Option 3: Windows Batch File

```cmd
start.bat
```

## 🌐 Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Dashboard** (after login): http://localhost:3000/dashboard

## 📡 API Endpoints

### Authentication Service (Port 8080)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/auth/authorize` | Get Asgardeo authorization URL |
| POST | `/auth/callback` | Exchange authorization code for tokens |
| POST | `/auth/validate` | Validate JWT tokens |
| POST | `/auth/refresh` | Refresh access tokens |
| POST | `/auth/logout` | Logout user |

### Example API Usage

```javascript
// Get authorization URL
const response = await fetch('http://localhost:8080/auth/authorize');
const { authUrl } = await response.json();

// Exchange code for tokens
const tokenResponse = await fetch('http://localhost:8080/auth/callback', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ code: 'auth_code', state: 'state_value' })
});
```

## 🔧 Development

### Project Structure

```
├── bal-backend/               # Ballerina authentication service
│   ├── Ballerina.toml        # Ballerina project configuration
│   ├── Config.toml           # Application configuration (ignored)
│   ├── Config.toml.template  # Configuration template
│   └── main.bal              # Main service implementation
├── client/                   # Next.js frontend application
│   ├── app/                  # Next.js app directory
│   │   ├── dashboard/        # Protected dashboard page
│   │   ├── layout.tsx        # Root layout with AuthProvider
│   │   └── page.tsx          # Home page with login
│   └── lib/                  # Utility libraries
│       ├── auth-service.ts   # Authentication service client
│       └── auth-context.tsx  # React authentication context
├── package.json              # Root package.json with scripts
├── README.md                 # This file
└── .gitignore               # Git ignore rules
```

### Adding New Protected Routes

1. Create your page component
2. Wrap it with the `withAuth` HOC:

```tsx
import { withAuth } from '../lib/auth-context';

function MyProtectedPage() {
  return <div>Protected content</div>;
}

export default withAuth(MyProtectedPage);
```

### Accessing User Information

```tsx
import { useAuth } from '../lib/auth-context';

function MyComponent() {
  const { user, isAuthenticated, logout } = useAuth();
  
  return (
    <div>
      {isAuthenticated ? (
        <p>Welcome, {user?.name}!</p>
      ) : (
        <p>Please log in</p>
      )}
    </div>
  );
}
```

## 🔒 Security Features

- **OAuth2 Authorization Code Flow** for secure authentication
- **JWT Token Validation** on the backend
- **Automatic Token Refresh** to maintain sessions
- **CORS Configuration** for controlled access
- **Secure Token Storage** with proper lifecycle management
- **Protected Route Guards** to prevent unauthorized access

## 🛠️ Available Scripts

```bash
# Start both services concurrently
npm start

# Start only the authentication service
npm run start:auth

# Start only the client application
npm run start:client

# Install client dependencies
npm run install:client

# Build client for production
npm run build:client

# Lint client code
npm run lint:client
```

## 🚨 Troubleshooting

### Common Issues

1. **"Invalid organization" error**
   - Ensure your organization name in `Config.toml` matches your Asgardeo console URL

2. **CORS errors**
   - Verify the `corsAllowedOrigins` setting in the Ballerina service

3. **Token exchange fails**
   - Check that your client credentials are correct
   - Ensure the redirect URI matches exactly with Asgardeo configuration

4. **Authentication Required on dashboard**
   - Clear browser localStorage and try logging in again
   - Check browser console for any JavaScript errors

### Debug Mode

To run the Ballerina service in debug mode:

```bash
cd bal-backend
bal run --debug 5005
```

## 📝 Configuration Reference

### Asgardeo Configuration

| Field | Description | Example |
|-------|-------------|---------|
| `asgardeoClientId` | Your application's Client ID | `5OCfMRn7p8P4hrVJAqIWRbQkl0Aa` |
| `asgardeoClientSecret` | Your application's Client Secret | `B1wdNDkyGh14wInAbNuDeIlyXUJIfdNJcoeDtbpVELIa` |
| `asgardeoRedirectUri` | OAuth2 redirect URI | `http://localhost:3000/dashboard` |
| `asgardeoBaseUrl` | Asgardeo API base URL | `https://api.asgardeo.io/t/your-org/oauth2` |
| `asgardeoScope` | OAuth2 scopes | `openid profile` |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ballerina](https://ballerina.io/) - The cloud-native programming language
- [Asgardeo](https://asgardeo.io/) - Identity as a Service by WSO2
- [Next.js](https://nextjs.org/) - The React Framework for the Web
- [Tailwind CSS](https://tailwindcss.com/) - A utility-first CSS framework

## 📞 Support

If you encounter any issues or have questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Search existing [GitHub issues](https://github.com/your-username/your-repo/issues)
3. Create a new issue with detailed information
4. For Asgardeo-specific issues, contact: asgardeo-help@wso2.com
