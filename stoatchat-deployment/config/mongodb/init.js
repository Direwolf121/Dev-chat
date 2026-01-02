// MongoDB initialization script for Stoatchat
// This script runs when the MongoDB container is first created

db = db.getSiblingDB('stoatchat');

// Create collections
db.createCollection('users');
db.createCollection('servers');
db.createCollection('channels');
db.createCollection('messages');
db.createCollection('sessions');
db.createCollection('attachments');
db.createCollection('emojis');
db.createCollection('server_members');
db.createCollection('relationships');
db.createCollection('invites');

// Create indexes for users
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "created_at": -1 });
db.users.createIndex({ "last_seen": -1 });

// Create indexes for servers
db.servers.createIndex({ "owner": 1 });
db.servers.createIndex({ "name": 1 });
db.servers.createIndex({ "created_at": -1 });

// Create indexes for channels
db.channels.createIndex({ "server": 1 });
db.channels.createIndex({ "name": 1 });
db.channels.createIndex({ "type": 1 });

// Create indexes for messages
db.messages.createIndex({ "channel": 1, "created_at": -1 });
db.messages.createIndex({ "author": 1 });
db.messages.createIndex({ "server": 1 });
db.messages.createIndex({ "content": "text" });

// Create indexes for sessions
db.sessions.createIndex({ "user_id": 1 });
db.sessions.createIndex({ "token": 1 });
db.sessions.createIndex({ "expires_at": 1 }, { expireAfterSeconds: 0 });

// Create indexes for attachments
db.attachments.createIndex({ "message_id": 1 });
db.attachments.createIndex({ "filename": 1 });
db.attachments.createIndex({ "uploaded_at": -1 });

// Create indexes for emojis
db.emojis.createIndex({ "name": 1 });
db.emojis.createIndex({ "server": 1 });

// Create indexes for server members
db.server_members.createIndex({ "server": 1, "user": 1 }, { unique: true });
db.server_members.createIndex({ "user": 1 });

// Create indexes for relationships
db.relationships.createIndex({ "from_user": 1, "to_user": 1 }, { unique: true });
db.relationships.createIndex({ "to_user": 1 });
db.relationships.createIndex({ "status": 1 });

// Create indexes for invites
db.invites.createIndex({ "code": 1 }, { unique: true });
db.invites.createIndex({ "server": 1 });
db.invites.createIndex({ "created_by": 1 });
db.invites.createIndex({ "expires_at": 1 }, { expireAfterSeconds: 0 });

// Create default admin user (password should be changed immediately)
var adminUser = {
    _id: new ObjectId(),
    username: "admin",
    email: "admin@stoat.chat",
    password: "$2b$10$rOvFTJg6/8SH5K4K5J5J5O5K5J5J5O5K5J5J5O5K5J5J5O5K5J5J5O", // Placeholder, will be set properly
    discriminator: "0000",
    avatar: null,
    status: null,
    profile: {
        content: null,
        background: null
    },
    relations: [],
    badges: 1, // Developer badge
    flags: 0,
    privileged: true,
    bot: false,
    created_at: new Date(),
    last_seen: new Date()
};

try {
    db.users.insertOne(adminUser);
    print("Default admin user created. Please set a secure password.");
} catch (e) {
    print("Admin user may already exist or there was an error: " + e);
}

// Create system user for bot messages
var systemUser = {
    _id: new ObjectId(),
    username: "System",
    email: "system@stoat.chat",
    password: "$2b$10$systemUserPasswordThatShouldNeverBeUsedForLogin",
    discriminator: "0001",
    avatar: null,
    status: null,
    profile: {
        content: "System messages and notifications",
        background: null
    },
    relations: [],
    badges: 0,
    flags: 0,
    privileged: false,
    bot: true,
    created_at: new Date(),
    last_seen: new Date()
};

try {
    db.users.insertOne(systemUser);
    print("System user created for bot messages.");
} catch (e) {
    print("System user may already exist or there was an error: " + e);
}

print("MongoDB initialization completed successfully!");