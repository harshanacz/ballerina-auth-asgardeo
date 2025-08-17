import ballerina/http;
import ballerina/log;
import ballerina/url;
import ballerina/random;
import ballerina/regex;

// Configuration
configurable string asgardeoClientId = "<ur>";
configurable string asgardeoClientSecret = "<ur>";
configurable string asgardeoRedirectUri = "http://localhost:3000/dashboard";
configurable string asgardeoBaseUrl = "https://api.asgardeo.io/t/<ur>/oauth2";
configurable string asgardeoScope = "openid profile";
configurable int serverPort = 8080;

// Simple user type for responses
type UserInfo record {|
    string? email = ();
    string? name = ();
    string? given_name = ();
    string? family_name = ();
    string? picture = ();
    string? sub = ();
|};

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

    function init() {
        log:printInfo("🚀 Ballerina Authentication Service started successfully!");
        log:printInfo("📍 Server listening on http://localhost:" + serverPort.toString());
        log:printInfo("🔐 Asgardeo integration configured");
    }

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

        // Extract access token and get user info
        json|error accessTokenJson = tokenResponse.access_token;
        if accessTokenJson is error || accessTokenJson is () {
            return error("Access token not found in response");
        }
        
        string accessToken = accessTokenJson.toString();
        
        // Get user information from Asgardeo
        json|error userInfo = getUserInfo(accessToken);
        if userInfo is error {
            log:printError("Failed to get user info", userInfo);
            return error("Failed to get user information");
        }
        
        // Save or update user in Supabase database
        User|DatabaseError savedUser = saveUserFromOAuth(userInfo);
        if savedUser is DatabaseError {
            log:printError("Failed to save user to database: " + savedUser.message);
            // Continue with authentication even if database save fails
        }
        
        // Add user info to token response
        json responseWithUser = tokenResponse.clone();
        UserInfo user = extractUserInfo(userInfo);
        json userJson = {
            "email": user.email,
            "name": user.name,
            "given_name": user.given_name,
            "family_name": user.family_name,
            "picture": user.picture,
            "sub": user.sub
        };
        
        // If we successfully saved to database, include database user ID
        if savedUser is User {
            userJson = check userJson.mergeJson({"id": savedUser.id});
        }
        
        responseWithUser = check responseWithUser.mergeJson({"user": userJson});

        return responseWithUser;
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
    
    // Get current user profile
    resource function get user(@http:Header {name: "Authorization"} string? authorization) returns json|error {
        if authorization is () {
            return error("Authorization header missing");
        }
        
        string[] headerParts = regex:split(authorization, " ");
        if headerParts.length() != 2 || headerParts[0] != "Bearer" {
            return error("Invalid authorization header format");
        }
        
        string token = headerParts[1];
        json|error userInfo = getUserInfo(token);
        if userInfo is error {
            return error("Invalid or expired token");
        }
        
        UserInfo user = extractUserInfo(userInfo);
        return {
            "email": user.email,
            "name": user.name,
            "given_name": user.given_name,
            "family_name": user.family_name,
            "picture": user.picture,
            "sub": user.sub
        };
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

// Get user information from Asgardeo using access token
function getUserInfo(string accessToken) returns json|error {
    http:Client userInfoEndpoint = check new (asgardeoBaseUrl);
    
    map<string> headers = {"Authorization": "Bearer " + accessToken};
    
    http:Response response = check userInfoEndpoint->get("/userinfo", headers);
    
    if response.statusCode != 200 {
        return error("Failed to get user info");
    }
    
    return response.getJsonPayload();
}

// Extract user information from OAuth response
function extractUserInfo(json userInfo) returns UserInfo {
    UserInfo user = {};
    
    json|error emailJson = userInfo.email;
    if emailJson is json && emailJson is string {
        user.email = emailJson;
    }
    
    json|error nameJson = userInfo.name;
    if nameJson is json && nameJson is string {
        user.name = nameJson;
    }
    
    json|error givenNameJson = userInfo.given_name;
    if givenNameJson is json && givenNameJson is string {
        user.given_name = givenNameJson;
    }
    
    json|error familyNameJson = userInfo.family_name;
    if familyNameJson is json && familyNameJson is string {
        user.family_name = familyNameJson;
    }
    
    json|error pictureJson = userInfo.picture;
    if pictureJson is json && pictureJson is string {
        user.picture = pictureJson;
    }
    
    json|error subJson = userInfo.sub;
    if subJson is json && subJson is string {
        user.sub = subJson;
    }
    
    return user;
}

// Save user information from OAuth provider to Supabase database
function saveUserFromOAuth(json userInfo) returns User|DatabaseError {
    json|error emailJson = userInfo.email;
    json|error subJson = userInfo.sub;
    
    if emailJson is error || subJson is error {
        return {message: "Invalid user information from OAuth provider", code: "INVALID_OAUTH_DATA"};
    }
    
    string? nameStr = ();
    string? givenNameStr = ();
    string? familyNameStr = ();
    string? pictureStr = ();
    
    json|error nameJson = userInfo.name;
    if nameJson is json && nameJson is string {
        nameStr = nameJson;
    }
    
    json|error givenNameJson = userInfo.given_name;
    if givenNameJson is json && givenNameJson is string {
        givenNameStr = givenNameJson;
    }
    
    json|error familyNameJson = userInfo.family_name;
    if familyNameJson is json && familyNameJson is string {
        familyNameStr = familyNameJson;
    }
    
    json|error pictureJson = userInfo.picture;
    if pictureJson is json && pictureJson is string {
        pictureStr = pictureJson;
    }
    
    CreateUserRequest userRequest = {
        email: emailJson.toString(),
        name: nameStr,
        given_name: givenNameStr,
        family_name: familyNameStr,
        picture: pictureStr,
        sub: subJson.toString(),
        provider: "asgardeo"
    };
    
    return createOrUpdateUser(userRequest);
}

