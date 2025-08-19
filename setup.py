#!/usr/bin/env python3
"""
Setup script for Neo4j Feedback Integration
This script helps set up the development environment and verify all components are working
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def print_banner():
    """Print setup banner"""
    print("=" * 60)
    print("🚀 Neo4j Feedback Integration Setup")
    print("🌍 UN Environmental Governance App")
    print("=" * 60)

def check_python_version():
    """Check if Python version is compatible"""
    print("\n🐍 Checking Python version...")
    version = sys.version_info
    if version.major == 3 and version.minor >= 8:
        print(f"✅ Python {version.major}.{version.minor}.{version.micro} - Compatible")
        return True
    else:
        print(f"❌ Python {version.major}.{version.minor}.{version.micro} - Requires Python 3.8+")
        return False

def check_neo4j():
    """Check if Neo4j is available"""
    print("\n🗄️ Checking Neo4j availability...")
    
    # Try to connect to default Neo4j instance
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex(('localhost', 7687))
        sock.close()
        
        if result == 0:
            print("✅ Neo4j is running on localhost:7687")
            return True
        else:
            print("⚠️ Neo4j is not running on localhost:7687")
            return False
    except Exception as e:
        print(f"⚠️ Could not check Neo4j status: {e}")
        return False

def create_virtual_environment():
    """Create Python virtual environment"""
    print("\n🔧 Creating virtual environment...")
    
    env_path = Path("env")
    if env_path.exists():
        print("✅ Virtual environment already exists")
        return True
    
    try:
        subprocess.run([sys.executable, "-m", "venv", "env"], check=True)
        print("✅ Virtual environment created successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to create virtual environment: {e}")
        return False

def get_pip_command():
    """Get the correct pip command for the current OS"""
    if os.name == 'nt':  # Windows
        return os.path.join("env", "Scripts", "pip")
    else:  # Unix/Linux/macOS
        return os.path.join("env", "bin", "pip")

def get_python_command():
    """Get the correct python command for the current OS"""
    if os.name == 'nt':  # Windows
        return os.path.join("env", "Scripts", "python")
    else:  # Unix/Linux/macOS
        return os.path.join("env", "bin", "python")

def install_dependencies():
    """Install Python dependencies"""
    print("\n📦 Installing dependencies...")
    
    python_cmd = get_python_command()

    try:
        # Upgrade pip using python -m pip instead of direct pip command
        print("🔄 Upgrading pip...")
        subprocess.run([python_cmd, "-m", "pip", "install", "--upgrade", "pip"], check=True)
        print("✅ Pip upgraded successfully")
        
        # Install dependencies
        print("🔄 Installing requirements...")
        subprocess.run([python_cmd, "-m", "pip", "install", "-r", "requirements.txt"], check=True)
        print("✅ Dependencies installed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install dependencies: {e}")
        return False

def create_env_file():
    """Create .env file from template"""
    print("\n⚙️ Setting up environment configuration...")
    
    env_file = Path(".env")
    env_example = Path(".env.example")
    
    if env_file.exists():
        print("✅ .env file already exists")
        return True
    
    if env_example.exists():
        try:
            shutil.copy(env_example, env_file)
            print("✅ .env file created from template")
            print("⚠️ Please update .env with your Neo4j credentials")
            return True
        except Exception as e:
            print(f"❌ Failed to create .env file: {e}")
            return False
    else:
        print("❌ .env.example file not found")
        return False

def verify_installation():
    """Verify that all components can be imported"""
    print("\n🔍 Verifying installation...")
    
    # Get Python command for virtual environment
    if os.name == 'nt':  # Windows
        python_cmd = os.path.join("env", "Scripts", "python")
    else:  # Unix/Linux/macOS
        python_cmd = os.path.join("env", "bin", "python")

    test_imports = [
        "flask",
        "flask_cors", 
        "neo4j",
        "marshmallow",
        "requests"
    ]
    
    all_good = True
    for module in test_imports:
        try:
            result = subprocess.run([
                python_cmd, "-c", f"import {module}; print('✅ {module}')"
            ], capture_output=True, text=True, check=True)
            print(result.stdout.strip())
        except subprocess.CalledProcessError:
            print(f"❌ {module} - Import failed")
            all_good = False
    
    return all_good

def create_project_structure():
    """Create necessary project directories"""
    print("\n📁 Creating project structure...")
    
    directories = [
        "logs",
        "tests",
        "config"
    ]
    
    for directory in directories:
        dir_path = Path(directory)
        if not dir_path.exists():
            try:
                dir_path.mkdir(parents=True, exist_ok=True)
                print(f"✅ Created directory: {directory}")
            except Exception as e:
                print(f"❌ Failed to create directory {directory}: {e}")
        else:
            print(f"✅ Directory exists: {directory}")

def display_next_steps():
    """Display next steps for the user"""
    print("\n" + "=" * 60)
    print("🎉 Setup Complete! Next Steps:")
    print("=" * 60)
    
    print("\n1. 🗄️ Neo4j Setup:")
    print("   - Make sure Neo4j is installed and running")
    print("   - Default URL: bolt://localhost:7687")
    print("   - Default username: neo4j")
    print("   - Set your password in .env file")
    
    print("\n2. ⚙️ Configuration:")
    print("   - Update the .env file with your credentials")
    print("   - Check Neo4j connection settings")
    
    print("\n3. 🚀 Start the API:")
    if os.name == 'nt':  # Windows
        print("   env\\Scripts\\python app.py")
    else:  # Unix/Linux/macOS
        print("   env/bin/python app.py")

    print("\n4. 🧪 Test the API:")
    if os.name == 'nt':  # Windows
        print("   env\\Scripts\\python test_api.py --test")
    else:  # Unix/Linux/macOS
        print("   env/bin/python test_api.py --test")

    print("\n5. 📊 View API endpoints:")
    print("   - Health: http://localhost:8000/api/health")
    print("   - Feedback: http://localhost:8000/api/feedback")
    print("   - Analytics: http://localhost:8000/api/feedback/analytics")
    
    print("\n📖 For more information, check the README.md file")

def main():
    """Main setup function"""
    print_banner()
    
    # Check Python version
    if not check_python_version():
        print("\n❌ Setup failed: Incompatible Python version")
        sys.exit(1)
    
    # Create project structure
    create_project_structure()
    
    # Create virtual environment
    if not create_virtual_environment():
        print("\n❌ Setup failed: Could not create virtual environment")
        sys.exit(1)
    
    # Install dependencies
    if not install_dependencies():
        print("\n❌ Setup failed: Could not install dependencies")
        sys.exit(1)
    
    # Create environment file
    create_env_file()
    
    # Verify installation
    if not verify_installation():
        print("\n⚠️ Some components may not be working correctly")
    
    # Check Neo4j
    check_neo4j()
    
    # Display next steps
    display_next_steps()

if __name__ == "__main__":
    main()