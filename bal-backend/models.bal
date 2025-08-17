import ballerina/time;

// User data model for Supabase
public type User record {|
    string id?;
    string email;
    string name?;
    string given_name?;
    string family_name?;
    string picture?;
    string sub?; // Subject from OAuth provider
    string provider?; // OAuth provider (e.g., "asgardeo")
    time:Utc created_at?;
    time:Utc updated_at?;
    boolean is_active?;
|};

// User creation request
public type CreateUserRequest record {|
    string email;
    string name?;
    string given_name?;
    string family_name?;
    string picture?;
    string sub;
    string provider?;
|};

// User update request
public type UpdateUserRequest record {|
    string? name;
    string? given_name;
    string? family_name;
    string? picture;
    boolean? is_active;
|};

// Database response types
public type UserCreateResponse record {|
    string id;
    string email;
    string? name;
    time:Utc created_at;
|};

public type DatabaseError record {|
    string message;
    string? code;
|};
