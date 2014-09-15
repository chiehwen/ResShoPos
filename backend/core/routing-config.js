/**
 * Directly from fnakstad
 * https://github.com/fnakstad/angular-client-side-auth/blob/master/client/js/routingConfig.js
 */

(function (exports) {

    var config = {

        /* List all the roles you wish to use in the app
         * You have a max of 31 before the bit shift pushes the accompanying integer out of
         * the memory footprint for an integer
         */
        roles: [
            'anon',
            'user',
            'kitchen',
            'bar',
            'manager',
            'admin',
            'root'
        ],

        /*
         Build out all the access levels you want referencing the roles listed above
         You can use the "*" symbol to represent access to all roles
         */
        accessLevels: {
            'anon': ['anon'],
            'user': ['user'],
            'kitchen': ['kitchen'],
            'bar': ['bar'],
            'manager': ['manager'],
            'admin': ['admin'],
            'root': ['root']
        }

    };

    /*
     Method to build a distinct bit mask for each role
     It starts off with "1" and shifts the bit to the left for each element in the
     roles array parameter
     */
    function buildRoles(roles) {

        var bitMask = "01";
        var userRoles = {};

        for (var role in roles) {
            var intCode = parseInt(bitMask, 2);
            userRoles[roles[role]] = {
                bitMask: intCode,
                title: roles[role]
            };
            bitMask = (intCode << 1).toString(2);
        }

        return userRoles;
    }

    /*
     This method builds access level bit masks based on the accessLevelDeclaration parameter which must
     contain an array for each access level containing the allowed user roles.
     */
    function buildAccessLevels(accessLevelDeclarations, userRoles) {

        var accessLevels = {},
            resultBitMask,
            role;
        for (var level in accessLevelDeclarations) {

            if (typeof accessLevelDeclarations[level] === 'string') {
                if (accessLevelDeclarations[level] === '*') {

                    resultBitMask = '';

                    for (role in userRoles) {
                        resultBitMask += "1";
                    }
                    //accessLevels[level] = parseInt(resultBitMask, 2);
                    accessLevels[level] = {
                        bitMask: parseInt(resultBitMask, 2),
                        title: accessLevelDeclarations[level]
                    };
                }
                else {
                    console.log("Access Control Error: Could not parse '" + accessLevelDeclarations[level] + "' as access definition for level '" + level + "'");
                }
            }
            else {

                resultBitMask = 0;
                for (role in accessLevelDeclarations[level]) {
                    if (userRoles.hasOwnProperty(accessLevelDeclarations[level][role])) {
                        resultBitMask = resultBitMask | userRoles[accessLevelDeclarations[level][role]].bitMask;
                    }
                    else {
                        console.log("Access Control Error: Could not find role '" + accessLevelDeclarations[level][role] + "' in registered roles while building access for '" + level + "'");
                    }
                }
                accessLevels[level] = {
                    bitMask: resultBitMask,
                    title: accessLevelDeclarations[level][role]
                };
            }
        }

        return accessLevels;
    }


    exports.userRoles = buildRoles(config.roles);
    exports.accessLevels = buildAccessLevels(config.accessLevels, exports.userRoles);

    exports.userCan =
    {
        read: {
            Site: exports.accessLevels.user,
            Users: exports.accessLevels.manager,
            FbUsers: exports.accessLevels.manager,
            UserFinalization: exports.accessLevels.user,
            Order: exports.accessLevels.user,
            OrderItem: exports.accessLevels.user,
            Category: exports.accessLevels.anon,
            Menudata: exports.accessLevels.anon,
            Table: exports.accessLevels.user,
            Invoice: exports.accessLevels.user
        },
        readOne: {
            Site: exports.accessLevels.user,
            Users: exports.accessLevels.manager,
            FbUsers: exports.accessLevels.manager,
            UserFinalization: exports.accessLevels.user,
            Order: exports.accessLevels.user,
            OrderItem: exports.accessLevels.user,
            Category: exports.accessLevels.anon,
            Menudata: exports.accessLevels.anon,
            Table: exports.accessLevels.user,
            Invoice: exports.accessLevels.user
        },
        create: {
            Site: exports.accessLevels.root,
            Users: exports.accessLevels.manager,
            FbUsers: exports.accessLevels.manager,
            UserFinalization: exports.accessLevels.user,
            Order: exports.accessLevels.user,
            OrderItem: exports.accessLevels.user,
            Category: exports.accessLevels.manager,
            Menudata: exports.accessLevels.manager,
            Table: exports.accessLevels.manager,
            Invoice: exports.accessLevels.user
        },
        update: {
            Site: exports.accessLevels.admin,
            Users: exports.accessLevels.manager,
            FbUsers: exports.accessLevels.manager,
            UserFinalization: exports.accessLevels.user,
            Order: exports.accessLevels.user,
            OrderItem: exports.accessLevels.user,
            Category: exports.accessLevels.manager,
            Menudata: exports.accessLevels.manager,
            Table: exports.accessLevels.manager,
            Invoice: exports.accessLevels.user
        },
        delete: {
            Site: exports.accessLevels.root,
            Users: exports.accessLevels.manager,
            FbUsers: exports.accessLevels.manager,
            UserFinalization: exports.accessLevels.user,
            Order: exports.accessLevels.user,
            OrderItem: exports.accessLevels.user,
            Category: exports.accessLevels.manager,
            Menudata: exports.accessLevels.manager,
            Table: exports.accessLevels.manager,
            Invoice: exports.accessLevels.user
        },
        deleteAll: {
            Site: exports.accessLevels.root,
            Users: exports.accessLevels.root,
            FbUsers: exports.accessLevels.root,
            UserFinalization: exports.accessLevels.root,
            Order: exports.accessLevels.root,
            OrderItem: exports.accessLevels.root,
            Category: exports.accessLevels.root,
            Menudata: exports.accessLevels.root,
            Table: exports.accessLevels.root,
            Invoice: exports.accessLevels.root
        },
        accessBar: exports.accessLevels.bar,
        accessAnalytic: exports.accessLevels.user,
        accessOrder: exports.accessLevels.manager,
        accessMenuData: exports.accessLevels.manager,
        accessUserFinalization: exports.accessLevels.manager,
        accessUser: exports.accessLevels.admin,
        accessSetting: exports.accessLevels.admin,
        deleteOrderItem: exports.accessLevels.manager
    };

})(typeof exports === 'undefined' ? this : exports);


