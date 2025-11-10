# Firebase Storage Setup Instructions

## CRITICAL: Enable Firebase Storage First!

The 404 error means Firebase Storage is NOT enabled in your project.

### Step 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ams-ml-project**
3. Click **Storage** in the left sidebar
4. Click **Get Started** button
5. Choose **Start in production mode** (or test mode for development)
6. Select a **location** for your bucket (choose closest to your users)
7. Click **Done**

This will create the Storage bucket: `ams-ml-project.firebasestorage.app`

### Step 2: Deploy Storage Rules

**Option A: Via Firebase Console**
1. In Firebase Console → **Storage** → **Rules** tab
2. Copy the contents from `storage.rules` file
3. Paste into the rules editor
4. Click **Publish**

**Option B: Via Firebase CLI**
```bash
firebase login
firebase use ams-ml-project
firebase deploy --only storage
```

### Step 3: Verify Setup

After enabling Storage, you should see:
- Storage bucket exists in Firebase Console
- Rules are deployed (check Rules tab)
- Files can be uploaded

### Current Storage Rules

The rules allow:
- ✅ Authenticated users can read/write employee photos
- ✅ Authenticated users can read/write attendance photos
- ✅ All operations require authentication

### Troubleshooting

If you still get 404 errors:
1. Verify Storage is enabled in Firebase Console
2. Check that the bucket name matches: `ams-ml-project.firebasestorage.app`
3. Ensure Storage rules are deployed
4. Try uploading a test file manually in Firebase Console to verify bucket works

