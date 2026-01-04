# Supabase Integration Setup Guide

## Prerequisites

1. **Supabase Account**: Sign up at [supabase.com](https://supabase.com)
2. **Flutter Project**: This guide assumes you have the Flutter project ready

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Choose a project name (e.g., "cantino-print-storage")
3. Choose a database password (save this securely)
4. Select a region close to your users
5. Wait for the project to be created

## Step 2: Get Project Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://xxxxxxxxxxxxx.supabase.co`)
   - **Anon public key** (starts with `eyJhbGciOi...`)

## Step 3: Update Configuration

1. Open `lib/services/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // ... rest of the code stays the same
}
```

## Step 4: Create Storage Bucket

1. In Supabase dashboard, go to **Storage**
2. Click **New bucket**
3. Bucket name: `print-documents`
4. Make it **Public** (so users can access their uploaded files)
5. Click **Create bucket**

## Step 5: Set Up Storage Policies (Row Level Security)

You need to create policies so users can only access their own files.

### 5.1 Enable RLS on Storage

1. Go to **Storage** → **Policies**
2. Click on the `print-documents` bucket
3. Click **New Policy**

### 5.2 Create Upload Policy

```sql
-- Allow authenticated users to upload files to their own folder
CREATE POLICY "Users can upload to own folder" ON storage.objects
FOR INSERT WITH CHECK (
  auth.uid()::text = (storage.foldername(name))[1] 
  AND bucket_id = 'print-documents'
);
```

### 5.3 Create View Policy

```sql
-- Allow authenticated users to view files in their own folder
CREATE POLICY "Users can view own files" ON storage.objects
FOR SELECT USING (
  auth.uid()::text = (storage.foldername(name))[1] 
  AND bucket_id = 'print-documents'
);
```

### 5.4 Create Delete Policy

```sql
-- Allow authenticated users to delete files in their own folder
CREATE POLICY "Users can delete own files" ON storage.objects
FOR DELETE USING (
  auth.uid()::text = (storage.foldername(name))[1] 
  AND bucket_id = 'print-documents'
);
```

## Step 6: Set Up Authentication Bridge

Since you're using Firebase Auth, you need to create a bridge. The current implementation uses Firebase UIDs directly as folder names in Supabase Storage.

### File Structure in Storage:
```
print-documents/
├── {firebase_user_id_1}/
│   ├── {job_id_1}/
│   │   └── document.pdf
│   └── {job_id_2}/
│       └── another_doc.pdf
└── {firebase_user_id_2}/
    └── {job_id_3}/
        └── user2_doc.pdf
```

## Step 7: Test the Integration

1. Run `flutter pub get` to install new dependencies
2. Start your app
3. Login with Firebase Auth
4. Try uploading a PDF file
5. Check Supabase Storage dashboard to see if files are uploaded

## Security Considerations

1. **File Size**: Limited to 10MB per file
2. **File Type**: Only PDF files allowed
3. **Access Control**: Users can only access their own files
4. **Firebase-Supabase Bridge**: Firebase UIDs are used as folder names

## Troubleshooting

### Common Issues:

1. **"Not authenticated" error**: 
   - Check if Supabase URL and anon key are correct
   - Verify storage policies are set up correctly

2. **"RLS policy violation"**:
   - Check if the storage policies match the folder structure
   - Ensure Firebase user is logged in

3. **File upload fails**:
   - Check internet connection
   - Verify file is PDF and under 10MB
   - Check browser console for detailed errors

4. **Files not showing**:
   - Verify the bucket is public
   - Check if storage policies allow SELECT operations

## Production Considerations

1. **Environment Variables**: Move credentials to environment variables
2. **Error Handling**: Add more robust error handling
3. **Monitoring**: Set up monitoring for storage usage
4. **Backup**: Consider backup strategies for important files
5. **CDN**: Consider using a CDN for better file delivery performance

## File Organization Strategy

The current implementation uses a simple user/job structure:
- `/{firebase_uid}/{job_id}/{filename}`
- This makes it easy to manage permissions and organize files
- Each print job has its own folder for potential future enhancements