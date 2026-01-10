# Environment Variables Setup

This application uses environment variables to securely store sensitive configuration data like database credentials.

## Setup Instructions

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the .env file** and add your actual Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-actual-anon-key-here
   ```

3. **Where to find your credentials:**
   - Go to your [Supabase Dashboard](https://supabase.com/dashboard)
   - Select your project
   - Go to Settings → API
   - Copy the **Project URL** (for SUPABASE_URL)
   - Copy the **anon/public** key (for SUPABASE_ANON_KEY)

## Important Security Notes

⚠️ **NEVER commit the .env file to version control!**
- The `.env` file is already added to `.gitignore`
- Only commit `.env.example` with placeholder values
- Share credentials securely with team members outside of version control

## Files Structure

- `.env` - Contains actual credentials (gitignored, not committed)
- `.env.example` - Template file with placeholder values (committed to repo)

## Troubleshooting

If you get an error about missing credentials:
1. Make sure the `.env` file exists in the project root
2. Verify the credentials are correctly formatted (no quotes, no spaces around =)
3. Restart the application after modifying `.env`

## For Team Members

When cloning this repository:
1. Copy `.env.example` to `.env`
2. Ask the project lead for the actual credentials
3. Update your local `.env` file with the provided credentials
