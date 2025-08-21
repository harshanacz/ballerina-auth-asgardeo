#  Ballerina Authentication 

A modern fullstack authentication application demonstrating OAuth2 integration between Ballerina backend services, Asgardeo (WSO2 Identity Server), and Supabase database with a Next.js frontend.

##  Architecture

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

1. Check the [troubleshooting section](#-troubleshooting)
2. Search existing [GitHub issues](https://github.com/your-username/your-repo/issues)
3. Create a new issue with detailed information
4. For Asgardeo-specific issues, contact: asgardeo-help@wso2.com

