# Firebase Realtime Database Security Rules

Copy and paste these rules into your Firebase Realtime Database Rules section:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        ".validate": "newData.hasChildren(['name', 'email', 'phone', 'studentId', 'branch', 'semester', 'hostel', 'dietaryPreference', 'notificationsEnabled'])",
        "name": {
          ".validate": "newData.isString() && newData.val().length > 0"
        },
        "email": {
          ".validate": "newData.isString() && newData.val().matches(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$/i)"
        },
        "phone": {
          ".validate": "newData.isString() && newData.val().length >= 10"
        },
        "studentId": {
          ".validate": "newData.isString() && newData.val().length > 0"
        },
        "branch": {
          ".validate": "newData.isString()"
        },
        "semester": {
          ".validate": "newData.isString()"
        },
        "hostel": {
          ".validate": "newData.isString()"
        },
        "dietaryPreference": {
          ".validate": "newData.isString()"
        },
        "notificationsEnabled": {
          ".validate": "newData.isBoolean()"
        },
        "profilePicUrl": {
          ".validate": "newData.isString()"
        },
        "createdAt": {
          ".validate": "newData.isNumber()"
        }
      }
    },
    "printJobs": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid",
        "$jobId": {
          ".validate": "newData.hasChildren(['id', 'code', 'fileName', 'timestamp', 'status', 'pageCount'])",
          "id": {
            ".validate": "newData.isString()"
          },
          "code": {
            ".validate": "newData.isString() && newData.val().length == 2"
          },
          "fileName": {
            ".validate": "newData.isString() && newData.val().length > 0"
          },
          "timestamp": {
            ".validate": "newData.isNumber()"
          },
          "status": {
            ".validate": "newData.isString() && (newData.val() == 'finished' || newData.val() == 'pending' || newData.val() == 'cancelled')"
          },
          "pageCount": {
            ".validate": "newData.isNumber() && newData.val() > 0"
          },
          "fileUrl": {
            ".validate": "newData.isString()"
          }
        }
      }
    },
    "foodItems": {
      ".read": "auth != null",
      ".write": false,
      "$itemId": {
        ".validate": "newData.hasChildren(['id', 'name', 'description', 'price', 'imageUrl', 'category', 'isVegetarian', 'isAvailable', 'preparationTime'])",
        "id": {
          ".validate": "newData.isString()"
        },
        "name": {
          ".validate": "newData.isString() && newData.val().length > 0"
        },
        "description": {
          ".validate": "newData.isString()"
        },
        "price": {
          ".validate": "newData.isNumber() && newData.val() > 0"
        },
        "imageUrl": {
          ".validate": "newData.isString()"
        },
        "category": {
          ".validate": "newData.isString()"
        },
        "isVegetarian": {
          ".validate": "newData.isBoolean()"
        },
        "isAvailable": {
          ".validate": "newData.isBoolean()"
        },
        "preparationTime": {
          ".validate": "newData.isNumber() && newData.val() > 0"
        },
        "tags": {
          ".validate": "newData.hasChildren()"
        }
      }
    },
    "orders": {
      "$uid": {
        ".read": "$uid === auth.uid",
        ".write": "$uid === auth.uid"
      }
    }
  }
}
```

## Key Security Features:

### Users Data (`users/{uid}/`)
- ✅ Users can only read/write their own data
- ✅ Validates all required fields on signup
- ✅ Email validation pattern matching
- ✅ Phone number minimum length validation

### Print Jobs (`printJobs/{uid}/{jobId}`)
- ✅ **User-specific isolation**: Each user can only access their own print jobs
- ✅ Print jobs are scoped under user ID: `printJobs/{uid}/`
- ✅ Validates job status (finished/pending/cancelled)
- ✅ Validates code is exactly 2 characters
- ✅ Validates required fields (id, code, fileName, timestamp, status, pageCount)

### Food Items (`foodItems/{itemId}`)
- ✅ All authenticated users can read (browse menu)
- ✅ Write restricted (admin-only, manage through console)
- ✅ Validates all required fields
- ✅ Price and preparation time must be positive numbers

### Orders (`orders/{uid}/`)
- ✅ User-specific isolation
- ✅ Users can only access their own orders

## How to Apply:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project **foodify-59a7f**
3. Click **Realtime Database** → **Rules** tab
4. Copy the rules above
5. Paste into the editor
6. Click **Publish**

## Testing:

After publishing, test that:
- ✅ User A cannot see User B's print jobs
- ✅ User can create/read/update/delete only their own print jobs
- ✅ All users can browse food items
- ✅ Users can only access their own profile data
