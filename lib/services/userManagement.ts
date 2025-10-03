import { getAdminAuth } from '@/lib/firebase-admin';
import { Role } from '@/lib/types/permissions';

export interface UserClaims {
  role?: Role;
  roles?: Role[];
  permissions?: string[];
  [key: string]: any;
}

export class UserManagementService {
  private auth = getAdminAuth();

  /**
   * Set custom claims for a user
   */
  async setUserClaims(uid: string, claims: UserClaims): Promise<void> {
    try {
      await this.auth.setCustomUserClaims(uid, claims);
      console.log(`Custom claims set for user ${uid}:`, claims);
    } catch (error) {
      console.error('Error setting custom claims:', error);
      throw new Error('Failed to set user claims');
    }
  }

  /**
   * Add a role to a user
   */
  async addUserRole(uid: string, role: Role): Promise<void> {
    try {
      const user = await this.auth.getUser(uid);
      const existingClaims = user.customClaims || {};
      const existingRoles = existingClaims.roles || [];

      if (!existingRoles.includes(role)) {
        const updatedRoles = [...existingRoles, role];
        await this.setUserClaims(uid, {
          ...existingClaims,
          roles: updatedRoles,
          role: role // Keep single role for backward compatibility
        });
      }
    } catch (error) {
      console.error('Error adding user role:', error);
      throw new Error('Failed to add user role');
    }
  }

  /**
   * Remove a role from a user
   */
  async removeUserRole(uid: string, role: Role): Promise<void> {
    try {
      const user = await this.auth.getUser(uid);
      const existingClaims = user.customClaims || {};
      const existingRoles = existingClaims.roles || [];

      const updatedRoles = existingRoles.filter((r: string) => r !== role);
      const primaryRole = updatedRoles.length > 0 ? updatedRoles[0] : null;

      await this.setUserClaims(uid, {
        ...existingClaims,
        roles: updatedRoles,
        role: primaryRole
      });
    } catch (error) {
      console.error('Error removing user role:', error);
      throw new Error('Failed to remove user role');
    }
  }

  /**
   * Set primary role for a user (replaces existing roles)
   */
  async setUserRole(uid: string, role: Role): Promise<void> {
    try {
      const user = await this.auth.getUser(uid);
      const existingClaims = user.customClaims || {};

      await this.setUserClaims(uid, {
        ...existingClaims,
        roles: [role],
        role: role
      });
    } catch (error) {
      console.error('Error setting user role:', error);
      throw new Error('Failed to set user role');
    }
  }

  /**
   * Get user with claims
   */
  async getUserWithClaims(uid: string) {
    try {
      const user = await this.auth.getUser(uid);
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        disabled: user.disabled,
        emailVerified: user.emailVerified,
        customClaims: user.customClaims || {},
        metadata: {
          creationTime: user.metadata.creationTime,
          lastSignInTime: user.metadata.lastSignInTime
        }
      };
    } catch (error) {
      console.error('Error getting user:', error);
      throw new Error('Failed to get user');
    }
  }

  /**
   * List all users with their claims
   */
  async listUsers(maxResults: number = 1000): Promise<any[]> {
    try {
      const listUsersResult = await this.auth.listUsers(maxResults);
      return listUsersResult.users.map(user => ({
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        disabled: user.disabled,
        emailVerified: user.emailVerified,
        customClaims: user.customClaims || {},
        metadata: {
          creationTime: user.metadata.creationTime,
          lastSignInTime: user.metadata.lastSignInTime
        }
      }));
    } catch (error) {
      console.error('Error listing users:', error);
      throw new Error('Failed to list users');
    }
  }

  /**
   * Create a new user with role
   */
  async createUserWithRole(email: string, password: string, role: Role, displayName?: string): Promise<string> {
    try {
      const userRecord = await this.auth.createUser({
        email,
        password,
        displayName,
        emailVerified: false
      });

      // Set the role immediately
      await this.setUserRole(userRecord.uid, role);

      return userRecord.uid;
    } catch (error) {
      console.error('Error creating user:', error);
      throw new Error('Failed to create user');
    }
  }

  /**
   * Delete a user
   */
  async deleteUser(uid: string): Promise<void> {
    try {
      await this.auth.deleteUser(uid);
      console.log(`User ${uid} deleted successfully`);
    } catch (error) {
      console.error('Error deleting user:', error);
      throw new Error('Failed to delete user');
    }
  }

  /**
   * Disable/Enable user
   */
  async setUserDisabled(uid: string, disabled: boolean): Promise<void> {
    try {
      await this.auth.updateUser(uid, { disabled });
      console.log(`User ${uid} ${disabled ? 'disabled' : 'enabled'} successfully`);
    } catch (error) {
      console.error('Error updating user disabled status:', error);
      throw new Error('Failed to update user status');
    }
  }

  /**
   * Initialize default admin user from environment
   */
  async initializeDefaultAdmin(): Promise<void> {
    const adminEmail = process.env.DEFAULT_ADMIN_EMAIL;
    const adminPassword = process.env.DEFAULT_ADMIN_PASSWORD;

    if (!adminEmail || !adminPassword) {
      console.log('No default admin credentials provided in environment');
      return;
    }

    try {
      // Try to get user by email first
      let user;
      try {
        user = await this.auth.getUserByEmail(adminEmail);
        console.log('Default admin user already exists');
      } catch (error) {
        // User doesn't exist, create it
        const uid = await this.createUserWithRole(
          adminEmail, 
          adminPassword, 
          Role.SUPER_ADMIN,
          'Default Admin'
        );
        console.log('Default admin user created with UID:', uid);
        return;
      }

      // If user exists, ensure they have admin role
      const claims = user.customClaims || {};
      if (!claims.role || !claims.roles?.includes(Role.SUPER_ADMIN)) {
        await this.setUserRole(user.uid, Role.SUPER_ADMIN);
        console.log('Admin role assigned to existing user');
      }
    } catch (error) {
      console.error('Error initializing default admin:', error);
    }
  }
}

export const userManagement = new UserManagementService();