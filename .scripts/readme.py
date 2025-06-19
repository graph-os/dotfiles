#!/usr/bin/env python3
"""
Enhanced README and documentation viewer for dotfiles.
Displays README, INSTALL, CONFIG, CHEATSHEET files and more.
"""

import argparse
import os
import sys
import subprocess
from pathlib import Path
from typing import List, Optional

try:
    import markdown
    MARKDOWN_AVAILABLE = True
except ImportError:
    MARKDOWN_AVAILABLE = False

# ANSI color codes for terminal output
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'


def find_dotfiles_dir() -> Path:
    """Find the dotfiles directory."""
    # Check environment variable first
    dotfiles_dir = os.environ.get('DOTFILES_DIR')
    if dotfiles_dir and Path(dotfiles_dir).exists():
        return Path(dotfiles_dir)
    
    # Common locations
    candidates = [
        Path.home() / '.dotfiles-public',
        Path.home() / '.dotfiles',
        Path.cwd(),
    ]
    
    for candidate in candidates:
        if candidate.exists() and any(candidate.glob('README*')):
            return candidate
    
    return Path.cwd()


def find_doc_files(directory: Path) -> List[Path]:
    """Find documentation files in the directory."""
    doc_patterns = [
        'README*',
        'INSTALL*',
        'CONFIG*',
        'CHEATSHEET*',
        'USAGE*',
        'QUICKSTART*',
        'SETUP*',
        'GETTING_STARTED*',
    ]
    
    files = []
    for pattern in doc_patterns:
        files.extend(directory.glob(pattern))
    
    # Sort by priority and then alphabetically
    priority_order = ['README', 'INSTALL', 'QUICKSTART', 'SETUP', 'CONFIG', 'USAGE', 'CHEATSHEET']
    
    def sort_key(file_path):
        name = file_path.stem.upper()
        if name in priority_order:
            return (priority_order.index(name), file_path.name)
        return (len(priority_order), file_path.name)
    
    return sorted(files, key=sort_key)


def read_file(file_path: Path) -> str:
    """Read file content with proper encoding handling."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except UnicodeDecodeError:
        try:
            with open(file_path, 'r', encoding='latin1') as f:
                return f.read()
        except Exception as e:
            return f"Error reading file: {e}"
    except Exception as e:
        return f"Error reading file: {e}"


def format_terminal(content: str, file_path: Path) -> str:
    """Format content for terminal display with colors."""
    output = []
    
    # Header
    output.append(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    output.append(f"{Colors.BOLD}{Colors.GREEN}{file_path.name}{Colors.RESET}")
    output.append(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    output.append("")
    
    # Content with basic formatting
    lines = content.split('\n')
    for line in lines:
        # Headers
        if line.startswith('# '):
            output.append(f"{Colors.BOLD}{Colors.YELLOW}{line}{Colors.RESET}")
        elif line.startswith('## '):
            output.append(f"{Colors.BOLD}{Colors.CYAN}{line}{Colors.RESET}")
        elif line.startswith('### '):
            output.append(f"{Colors.BOLD}{line}{Colors.RESET}")
        # Code blocks
        elif line.startswith('```'):
            output.append(f"{Colors.PURPLE}{line}{Colors.RESET}")
        elif line.strip().startswith('$') or line.strip().startswith('sudo'):
            output.append(f"{Colors.GREEN}{line}{Colors.RESET}")
        # Lists
        elif line.strip().startswith(('- ', '* ', '+ ')):
            output.append(f"{Colors.CYAN}{line}{Colors.RESET}")
        elif line.strip() and line[0].isdigit() and '. ' in line:
            output.append(f"{Colors.CYAN}{line}{Colors.RESET}")
        else:
            output.append(line)
    
    return '\n'.join(output)


def format_html(content: str, file_path: Path) -> str:
    """Format content as HTML."""
    if MARKDOWN_AVAILABLE and file_path.suffix.lower() in ['.md', '.markdown']:
        html_content = markdown.markdown(content, extensions=['codehilite', 'fenced_code'])
    else:
        # Simple HTML escaping and formatting
        content = content.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        content = content.replace('\n', '<br>\n')
        html_content = f"<pre>{content}</pre>"
    
    return f"""
<!DOCTYPE html>
<html>
<head>
    <title>{file_path.name}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }}
        h1, h2, h3 {{ color: #333; }}
        code {{ background: #f4f4f4; padding: 2px 4px; border-radius: 3px; }}
        pre {{ background: #f4f4f4; padding: 10px; border-radius: 5px; overflow-x: auto; }}
        blockquote {{ border-left: 4px solid #ddd; padding-left: 20px; margin-left: 0; }}
    </style>
</head>
<body>
{html_content}
</body>
</html>
"""


def get_aliases() -> str:
    """Extract aliases from bash_aliases file."""
    dotfiles_dir = find_dotfiles_dir()
    aliases_file = dotfiles_dir / '.bash_aliases'
    
    if not aliases_file.exists():
        return "No .bash_aliases file found."
    
    content = read_file(aliases_file)
    lines = content.split('\n')
    
    output = []
    output.append(f"{Colors.BOLD}{Colors.GREEN}Available Aliases:{Colors.RESET}")
    output.append("")
    
    current_section = None
    for line in lines:
        line = line.strip()
        
        # Section headers (comments)
        if line.startswith('# ') and not line.startswith('##'):
            section = line[2:].strip()
            if section != current_section:
                current_section = section
                output.append(f"{Colors.BOLD}{Colors.YELLOW}{section}{Colors.RESET}")
                output.append("")
        
        # Alias definitions
        elif line.startswith('alias '):
            try:
                alias_def = line[6:]  # Remove 'alias '
                if '=' in alias_def:
                    alias_name, alias_cmd = alias_def.split('=', 1)
                    alias_cmd = alias_cmd.strip('\'"')
                    output.append(f"  {Colors.CYAN}{alias_name.strip():<15}{Colors.RESET} {alias_cmd}")
            except:
                continue
    
    return '\n'.join(output)


def display_with_pager(content: str):
    """Display content using system pager if available."""
    try:
        # Try to use the system pager
        pager = os.environ.get('PAGER', 'less')
        if pager == 'less':
            # Use less with some nice options
            subprocess.run([pager, '-R', '-F', '-X'], input=content, text=True, check=True)
        else:
            subprocess.run([pager], input=content, text=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Fall back to plain print
        print(content)


def main():
    parser = argparse.ArgumentParser(
        description='Display dotfiles documentation and information.',
        epilog='Examples:\n'
               '  readme.py                    # Show all documentation\n'
               '  readme.py --file README.md   # Show specific file\n'
               '  readme.py --aliases          # Show aliases\n'
               '  readme.py --html > doc.html  # Export as HTML',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--file', '-f', help='Specific file to display')
    parser.add_argument('--aliases', '-a', action='store_true', help='Show aliases from .bash_aliases')
    parser.add_argument('--format', choices=['terminal', 'html', 'text'], default='terminal',
                       help='Output format (default: terminal)')
    parser.add_argument('--dir', help='Dotfiles directory (default: auto-detect)')
    parser.add_argument('--no-pager', action='store_true', help='Do not use pager for output')
    
    args = parser.parse_args()
    
    # Set dotfiles directory
    if args.dir:
        dotfiles_dir = Path(args.dir)
    else:
        dotfiles_dir = find_dotfiles_dir()
    
    if not dotfiles_dir.exists():
        print(f"{Colors.RED}Error: Dotfiles directory not found: {dotfiles_dir}{Colors.RESET}")
        sys.exit(1)
    
    # Handle aliases display
    if args.aliases:
        aliases_content = get_aliases()
        if args.no_pager or args.format != 'terminal':
            print(aliases_content)
        else:
            display_with_pager(aliases_content)
        return
    
    # Find files to display
    if args.file:
        file_path = dotfiles_dir / args.file
        if not file_path.exists():
            print(f"{Colors.RED}Error: File not found: {file_path}{Colors.RESET}")
            sys.exit(1)
        files_to_show = [file_path]
    else:
        files_to_show = find_doc_files(dotfiles_dir)
        if not files_to_show:
            print(f"{Colors.YELLOW}No documentation files found in {dotfiles_dir}{Colors.RESET}")
            sys.exit(1)
    
    # Generate output
    output_parts = []
    
    for file_path in files_to_show:
        content = read_file(file_path)
        
        if args.format == 'html':
            output_parts.append(format_html(content, file_path))
        elif args.format == 'text':
            output_parts.append(f"=== {file_path.name} ===\n\n{content}")
        else:  # terminal
            output_parts.append(format_terminal(content, file_path))
    
    # Display output
    final_output = '\n\n'.join(output_parts)
    
    if args.format == 'html':
        print(final_output)
    elif args.no_pager or args.format != 'terminal':
        print(final_output)
    else:
        display_with_pager(final_output)


if __name__ == '__main__':
    main()