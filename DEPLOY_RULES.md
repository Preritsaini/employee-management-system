# Deploy Firebase Rules

## Step 1: Enable Firebase Storage (REQUIRED FIRST!)

1. Go to: https://console.firebase.google.com/project/ams-ml-project/storage
2. Click **"Get Started"** button
3. Choose **"Start in production mode"**
4. Select a **location** (choose closest to your users)
5. Click **"Done"**

This will create the Storage bucket.

## Step 2: Deploy Rules via CLI

After enabling Storage, run:

```bash
# Deploy Storage rules
firebase deploy --only storage

# Deploy Firestore rules (if needed)
firebase deploy --only firestore:rules
```

## Step 3: Verify Rules are Deployed

1. **Storage Rules**: Go to Firebase Console → Storage → Rules tab
   - Should see your rules from `storage.rules`

2. **Firestore Rules**: Go to Firebase Console → Firestore Database → Rules tab
   - Should see your rules from `firestore.rules`

## Current Rules Status

✅ **Firestore Rules**: Ready to deploy
✅ **Storage Rules**: Ready to deploy (but Storage must be enabled first!)

## Troubleshooting

If you get "Storage has not been set up" error:
- You MUST enable Storage in Firebase Console first
- The bucket will be created automatically when you enable Storage
- Then you can deploy the rules

