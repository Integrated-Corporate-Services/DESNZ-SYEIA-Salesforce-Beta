/**
 * JIT Handler for Okta SSO
 * Handles Just-In-Time provisioning for user creation and updates during SAML authentication
 */
public class JitHandler implements Auth.SamlJitHandler {
    
    public class JitException extends Exception {}
    
    // Default values for new users
    private static final String DEFAULT_FIRST_NAME = 'Test';
    private static final String DEFAULT_LAST_NAME = 'User';
    private static final String DEFAULT_PROFILE_NAME = 'Standard User';
    private static final String DEFAULT_TIMEZONE = 'Europe/London';
    private static final String DEFAULT_LOCALE = 'en_GB';
    private static final String DEFAULT_EMAIL_ENCODING = 'UTF-8';
    private static final String DEFAULT_LANGUAGE = 'en_US';
    
    // SAML Attribute keys (must match Okta attribute mapping)
    private static final String ATTR_FIRST_NAME = 'Firstname';
    private static final String ATTR_LAST_NAME = 'Lastname';
    private static final String ATTR_EMAIL = 'Email';
    private static final String ATTR_ROLE = 'Title';
    
    /**
     * Handle new user creation during JIT provisioning
     */
    public User createUser(
        Id samlSsoProviderId,
        Id communityId,
        Id portalId,
        String federationIdentifier,
        Map<String, String> attributes,
        String assertion
    ) {
        if (String.isBlank(federationIdentifier)) {
            throw new JitException('Federation Identifier is required for user creation.');
        }
        
        User u = new User();
        
        // Set identifiers
        u.FederationIdentifier = federationIdentifier;
        u.Username = federationIdentifier;
        
        // Set name from attributes or use defaults
        u.FirstName = getAttributeOrDefault(attributes, ATTR_FIRST_NAME, DEFAULT_FIRST_NAME);
        u.LastName = getAttributeOrDefault(attributes, ATTR_LAST_NAME, DEFAULT_LAST_NAME);
        
        // Set email from attributes or fall back to federation identifier
        u.Email = getAttributeOrDefault(attributes, ATTR_EMAIL, federationIdentifier);
        
        // Set title/role if provided
        if (attributes.containsKey(ATTR_ROLE)) {
            u.Title = attributes.get(ATTR_ROLE);
        }
        
        // Set required User fields
        u.Alias = generateAlias(u.FirstName, u.LastName);
        u.TimeZoneSidKey = DEFAULT_TIMEZONE;
        u.LocaleSidKey = DEFAULT_LOCALE;
        u.EmailEncodingKey = DEFAULT_EMAIL_ENCODING;
        u.LanguageLocaleKey = DEFAULT_LANGUAGE;
        u.ProfileId = getProfileId(DEFAULT_PROFILE_NAME);
        u.IsActive = true;
        
        return u;
    }
    
    /**
     * Handle existing user updates during JIT provisioning
     */
    public void updateUser(
        Id userId,
        Id samlSsoProviderId,
        Id communityId,
        Id portalId,
        String federationIdentifier,
        Map<String, String> attributes,
        String assertion
    ) {
        if (userId == null) {
            throw new JitException('User Id is required for user update.');
        }
        
        User u = [
            SELECT Id, Username, Email, FirstName, LastName, Title, FederationIdentifier, IsActive
            FROM User 
            WHERE Id = :userId 
            LIMIT 1
        ];
        
        Boolean needsUpdate = false;
        
        // Ensure user is active on login
        if (!u.IsActive) {
            u.IsActive = true;
            needsUpdate = true;
        }
        
        // Update federation identifier if changed
        if (String.isNotBlank(federationIdentifier) && u.FederationIdentifier != federationIdentifier) {
            u.FederationIdentifier = federationIdentifier;
            needsUpdate = true;
        }
        
        // Update FirstName if different
        if (attributes.containsKey(ATTR_FIRST_NAME)) {
            String newFirstName = attributes.get(ATTR_FIRST_NAME);
            if (u.FirstName != newFirstName) {
                u.FirstName = newFirstName;
                needsUpdate = true;
            }
        }
        
        // Update LastName if different
        if (attributes.containsKey(ATTR_LAST_NAME)) {
            String newLastName = attributes.get(ATTR_LAST_NAME);
            if (u.LastName != newLastName) {
                u.LastName = newLastName;
                needsUpdate = true;
            }
        }
        
        // Update Email if different
        if (attributes.containsKey(ATTR_EMAIL)) {
            String newEmail = attributes.get(ATTR_EMAIL);
            if (u.Email != newEmail) {
                u.Email = newEmail;
                needsUpdate = true;
            }
        }
        
        // Update Title if different
        if (attributes.containsKey(ATTR_ROLE)) {
            String newTitle = attributes.get(ATTR_ROLE);
            if (u.Title != newTitle) {
                u.Title = newTitle;
                needsUpdate = true;
            }
        }
        
        // Only perform DML if something changed
        if (needsUpdate) {
            update u;
        }
    }
    
    /**
     * Get attribute value from map or return default if not present/blank
     */
    private String getAttributeOrDefault(Map<String, String> attributes, String key, String defaultValue) {
        if (attributes.containsKey(key) && String.isNotBlank(attributes.get(key))) {
            return attributes.get(key);
        }
        return defaultValue;
    }
    
    /**
     * Generate a user alias from first and last name
     * Format: first initial + up to 4 chars of last name (lowercase)
     */
    private String generateAlias(String firstName, String lastName) {
        String alias = '';
        
        if (String.isNotBlank(firstName)) {
            alias += firstName.substring(0, Math.min(firstName.length(), 1));
        }
        if (String.isNotBlank(lastName)) {
            alias += lastName.substring(0, Math.min(lastName.length(), 4));
        }
        
        if (String.isBlank(alias)) {
            alias = 'user';
        }
        
        return alias.toLowerCase();
    }
    
    /**
     * Get Profile Id by name
     */
    private Id getProfileId(String profileName) {
        List<Profile> profiles = [
            SELECT Id 
            FROM Profile 
            WHERE Name = :profileName 
            LIMIT 1
        ];
        
        if (profiles.isEmpty()) {
            throw new JitException('Profile not found: ' + profileName);
        }
        
        return profiles[0].Id;
    }
}