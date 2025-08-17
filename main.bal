import ballerina/http;
import ballerina/log;
import ballerina/url;
import ballerina/random;

// Configuration
configurable string asgardeoClientId = "5OCfMRn7p8P4hrVJAqIWRbQkl0Aa";
configurable string asgardeoClientSecret = "B1wdNDkyGh14wInAbNuDeIlyXUJIfdNJcoeDtbpVELIa";
configurable string asgardeoRedirectUri = "http://localhost:3000/dashboard";
configurable string asgardeoBaseUrl = "https://api.asgardeo.io/t/moderatocmaas/oauth2";
configurable string asgardeoScope = "openid profile";
configurable int serverPort = 8080;

// Service configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        allowMethods: ["GET", "POST", "OPTIONS"]
    }
}
service /auth on new http:Listener(serverPort) {

    // Generate authorization URL for Asgardeo
    resource function get authorize() returns json|error {
        string authUrl = asgardeoBaseUrl + "/authorize";
        
        float randomValue = random:createDecimal();
        int randomInt = <int>(randomValue * 1000000);
        string state = "state_" + randomInt.toString();
        
        string|url:Error clientIdEncoded = url:encode(asgardeoClientId, "UTF-8");
        string|url:Error redirectUriEncoded = url:encode(asgardeoRedirectUri, "UTF-8");
        string|url:Error scopeEncoded = url:encode(asgardeoScope, "UTF-8");
        string|url:Error stateEncoded = url:encode(state, "UTF-8");
        
        if (clientIdEncoded is string && redirectUriEncoded is string && 
            scopeEncoded is string && stateEncoded is string) {
            
            string finalUrl = authUrl + "?response_type=code&client_id=" + clientIdEncoded + 
                            "&redirect_uri=" + redirectUriEncoded + 
                            "&scope=" + scopeEncoded + 
                            "&state=" + stateEncoded;
            
            return {"authUrl": finalUrl};
        } else {
            return error("Failed to encode parameters");
        }
    }

    // Handle OAuth2 callback and exchange code for tokens
    resource function post callback(@http:Payload json payload) returns json|error {
        
        json|error codeJson = payload.code;
        if codeJson is error || codeJson is () {
            return error("Authorization code not provided");
        }
        
        string code = codeJson.toString();

        // Exchange authorization code for access token
        json|error tokenResponse = exchangeCodeForToken(code);
        
        if tokenResponse is error {
            log:printError("Token exchange failed", tokenResponse);
            return error("Token exchange failed");
        }

        return tokenResponse;
    }

    // Validate JWT token (simplified)
    resource function post validate(@http:Payload json payload) returns json {
        return {"valid": true, "message": "Token validation not implemented yet"};
    }

    // Refresh access token
    resource function post refresh(@http:Payload json payload) returns json|error {
        json|error refreshTokenJson = payload.refresh_token;
        if refreshTokenJson is error || refreshTokenJson is () {
            return error("Refresh token not provided");
        }
        
        string refreshToken = refreshTokenJson.toString();
        return refreshAccessToken(refreshToken);
    }

    // Logout endpoint
    resource function post logout(@http:Payload json payload) returns json {
        return {"message": "Logged out successfully"};
    }
}

function exchangeCodeForToken(string code) returns json|error {
    http:Client tokenEndpoint = check new (asgardeoBaseUrl);
    
    string formData = "grant_type=authorization_code" +
                     "&code=" + code +
                     "&redirect_uri=" + asgardeoRedirectUri +
                     "&client_id=" + asgardeoClientId +
                     "&client_secret=" + asgardeoClientSecret;

    http:Request tokenRequest = new;
    tokenRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");
    tokenRequest.setPayload(formData);

    http:Response response = check tokenEndpoint->post("/token", tokenRequest);
    
    if response.statusCode != 200 {
        return error("Token exchange failed");
    }

    return response.getJsonPayload();
}

function refreshAccessToken(string refreshToken) returns json|error {
    http:Client tokenEndpoint = check new (asgardeoBaseUrl);
    
    string formData = "grant_type=refresh_token" +
                     "&refresh_token=" + refreshToken +
                     "&client_id=" + asgardeoClientId +
                     "&client_secret=" + asgardeoClientSecret;

    http:Request refreshRequest = new;
    refreshRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");
    refreshRequest.setPayload(formData);

    http:Response response = check tokenEndpoint->post("/token", refreshRequest);
    
    if response.statusCode != 200 {
        return error("Token refresh failed");
    }

    return response.getJsonPayload();
}
