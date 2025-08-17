import ballerina/sql;
import ballerinax/postgresql;
import ballerina/uuid;
import ballerina/time;
import ballerina/log;

// Supabase Database Configuration
configurable string supabaseHost = "db.pembvcwdlcrmlnqifolt.supabase.co";
configurable int supabasePort = 5432;
configurable string supabaseDatabase = "postgres";
configurable string supabaseUsername = "postgres";
configurable string supabasePassword = "TkyWLHdCcJjjqYRh";

// Database client
final postgresql:Client dbClient;

function init() returns error? {
    dbClient = check new (
        host = supabaseHost,
        port = supabasePort,
        database = supabaseDatabase,
        username = supabaseUsername,
        password = supabasePassword,
        options = {
            ssl: {
                mode: "REQUIRE"
            }
        }
    );
    
    // Create users table if it doesn't exist
    _ = check createUsersTable();
    log:printInfo("Database connection established and users table ready");
}

// Create users table
function createUsersTable() returns sql:Error? {
    sql:ExecutionResult result = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email VARCHAR(255) UNIQUE NOT NULL,
            name VARCHAR(255),
            given_name VARCHAR(255),
            family_name VARCHAR(255),
            picture TEXT,
            sub VARCHAR(255) UNIQUE,
            provider VARCHAR(50) DEFAULT 'asgardeo',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            is_active BOOLEAN DEFAULT true
        )
    `);
    log:printInfo("Users table creation result", affectedRows = result.affectedRowCount);
}

// Create or update user
public function createOrUpdateUser(CreateUserRequest userRequest) returns User|DatabaseError {
    // Check if user exists by email or sub
    User|DatabaseError existingUser = getUserByEmailOrSub(userRequest.email, userRequest.sub);
    
    if existingUser is User {
        // Update existing user
        UpdateUserRequest updateRequest = {
            name: userRequest.name,
            given_name: userRequest.given_name,
            family_name: userRequest.family_name,
            picture: userRequest.picture,
            is_active: true
        };
        return updateUser(existingUser.id ?: "", updateRequest);
    }
    
    // Create new user
    string userId = uuid:createType1AsString();
    time:Utc currentTime = time:utcNow();
    
    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        INSERT INTO users (id, email, name, given_name, family_name, picture, sub, provider, created_at, updated_at, is_active)
        VALUES (${userId}, ${userRequest.email}, ${userRequest.name}, ${userRequest.given_name}, 
                ${userRequest.family_name}, ${userRequest.picture}, ${userRequest.sub}, 
                ${userRequest.provider ?: "asgardeo"}, ${currentTime}, ${currentTime}, ${true})
    `);
    
    if result is sql:Error {
        log:printError("Failed to create user", result);
        return {message: "Failed to create user", code: "DB_INSERT_ERROR"};
    }
    
    // Return the created user
    User|DatabaseError createdUser = getUserById(userId);
    return createdUser;
}

// Get user by ID
public function getUserById(string userId) returns User|DatabaseError {
    record {|
        string id;
        string email;
        string? name;
        string? given_name;
        string? family_name;
        string? picture;
        string? sub;
        string? provider;
        time:Utc? created_at;
        time:Utc? updated_at;
        boolean? is_active;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, email, name, given_name, family_name, picture, sub, provider, created_at, updated_at, is_active
        FROM users WHERE id = ${userId}
    `);
    
    if result is sql:Error {
        if result is sql:NoRowsError {
            return {message: "User not found", code: "USER_NOT_FOUND"};
        }
        log:printError("Failed to get user by ID", result);
        return {message: "Database query failed", code: "DB_QUERY_ERROR"};
    }
    
    User user = {
        id: result.id,
        email: result.email,
        name: result.name,
        given_name: result.given_name,
        family_name: result.family_name,
        picture: result.picture,
        sub: result.sub,
        provider: result.provider,
        created_at: result.created_at,
        updated_at: result.updated_at,
        is_active: result.is_active
    };
    
    return user;
}

// Get user by email or sub
public function getUserByEmailOrSub(string email, string sub) returns User|DatabaseError {
    record {|
        string id;
        string email;
        string? name;
        string? given_name;
        string? family_name;
        string? picture;
        string? sub;
        string? provider;
        time:Utc? created_at;
        time:Utc? updated_at;
        boolean? is_active;
    |}|sql:Error result = dbClient->queryRow(`
        SELECT id, email, name, given_name, family_name, picture, sub, provider, created_at, updated_at, is_active
        FROM users WHERE email = ${email} OR sub = ${sub}
    `);
    
    if result is sql:Error {
        if result is sql:NoRowsError {
            return {message: "User not found", code: "USER_NOT_FOUND"};
        }
        log:printError("Failed to get user by email or sub", result);
        return {message: "Database query failed", code: "DB_QUERY_ERROR"};
    }
    
    User user = {
        id: result.id,
        email: result.email,
        name: result.name,
        given_name: result.given_name,
        family_name: result.family_name,
        picture: result.picture,
        sub: result.sub,
        provider: result.provider,
        created_at: result.created_at,
        updated_at: result.updated_at,
        is_active: result.is_active
    };
    
    return user;
}

// Update user
public function updateUser(string userId, UpdateUserRequest updateRequest) returns User|DatabaseError {
    time:Utc currentTime = time:utcNow();
    
    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        UPDATE users SET 
            name = ${updateRequest.name},
            given_name = ${updateRequest.given_name},
            family_name = ${updateRequest.family_name},
            picture = ${updateRequest.picture},
            is_active = ${updateRequest.is_active ?: true},
            updated_at = ${currentTime}
        WHERE id = ${userId}
    `);
    
    if result is sql:Error {
        log:printError("Failed to update user", result);
        return {message: "Failed to update user", code: "DB_UPDATE_ERROR"};
    }
    
    // Return the updated user
    return getUserById(userId);
}

// Get all users (with pagination)
public function getAllUsers(int 'limit = 10, int offset = 0) returns User[]|DatabaseError {
    stream<User, sql:Error?> userStream = dbClient->query(`
        SELECT id, email, name, given_name, family_name, picture, sub, provider, created_at, updated_at, is_active
        FROM users 
        ORDER BY created_at DESC
        LIMIT ${'limit} OFFSET ${offset}
    `);
    
    User[] users = [];
    error? e = userStream.forEach(function(User user) {
        users.push(user);
    });
    
    if e is error {
        log:printError("Failed to get all users", e);
        return {message: "Failed to retrieve users", code: "DB_QUERY_ERROR"};
    }
    
    return users;
}

// Delete user (soft delete)
public function deleteUser(string userId) returns boolean|DatabaseError {
    sql:ExecutionResult|sql:Error result = dbClient->execute(`
        UPDATE users SET is_active = false, updated_at = ${time:utcNow()}
        WHERE id = ${userId}
    `);
    
    if result is sql:Error {
        log:printError("Failed to delete user", result);
        return {message: "Failed to delete user", code: "DB_UPDATE_ERROR"};
    }
    
    return result.affectedRowCount > 0;
}

// Close database connection
public function closeDbConnection() returns error? {
    check dbClient.close();
}
