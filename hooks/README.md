# Git Hooks

This directory contains Git hooks used in the repository to automate various tasks.

## Installing Hooks

To install these hooks:

1. Make sure the hook files are executable:

   ```bash
   chmod +x hooks/*
   ```

2. Copy or symlink the hooks to your `.git/hooks` directory:

   ```bash
   # Option 1: Copy hooks
   cp hooks/* .git/hooks/

   # Option 2: Symlink hooks (recommended)
   # First create the hooks directory if it doesn't exist
   mkdir -p .git/hooks

   # Then create symlinks for each hook file
   for hook in hooks/*; do
     ln -s "../../$hook" ".git/hooks/$(basename $hook)"
   done
   ```
