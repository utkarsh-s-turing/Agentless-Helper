#!/bin/bash
set -e  # Exit on error



# Ensure all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: bash $0 <PYTHON_VERSION> <VENV_NAME> <GIT_URL> <COMMIT_HASH>"
    exit 1
fi

# Input arguments
PYTHON_VERSION=$1
VENV_NAME=$2
GIT_URL=$3
COMMIT_HASH=$4
REPO_NAME=$(basename "$GIT_URL" .git)

# Function to install pyenv
install_pyenv() {
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        echo "Installing pyenv for Linux/macOS..."
        curl https://pyenv.run | bash
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "Installing pyenv-win on Windows..."
        if [ ! -d "$HOME/.pyenv" ]; then
            git clone https://github.com/pyenv-win/pyenv-win.git "$HOME/.pyenv"
        fi

        # Correct path for pyenv-win
        export PYENV_ROOT="$HOME/.pyenv/pyenv-win"
        export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

        # Persist environment variables for future sessions
        if ! grep -q 'export PYENV_ROOT="$HOME/.pyenv/pyenv-win"' ~/.bashrc; then
            echo 'export PYENV_ROOT="$HOME/.pyenv/pyenv-win"' >> ~/.bashrc
            echo 'export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"' >> ~/.bashrc
        fi

        echo "pyenv-win installed successfully."
    else
        echo "Unsupported OS. Please install pyenv manually."
        exit 1
    fi
}

# Ensure pyenv is installed
if ! command -v pyenv &> /dev/null; then
    echo "pyenv is not installed. Installing pyenv..."
    install_pyenv
fi

# **Fix the path issue**
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    export PYENV_ROOT="$HOME/.pyenv/pyenv-win"
else
    export PYENV_ROOT="$HOME/.pyenv"
fi

export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# Ensure pyenv is recognized
if ! command -v pyenv &> /dev/null; then
    echo "pyenv is still not found. Reloading shell environment..."
    source ~/.bashrc
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
fi

# Check again if pyenv is available
if ! command -v pyenv &> /dev/null; then
    echo "pyenv is still not found. Please restart your terminal manually and rerun this script."
    exit 1
fi

echo "pyenv detected successfully!"


# **Fix for Windows Git Bash Initialization**
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    pyenv rehash
else
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi




# Deactivate any currently active virtual environment
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "Deactivating existing virtual environment: $VIRTUAL_ENV"
    source deactivate || true
fi

# If using pyenv-virtualenv, deactivate explicitly
if command -v pyenv &> /dev/null; then
    if [[ "$(pyenv version-name)" != "system" ]]; then
        echo "Deactivating pyenv virtual environment: $(pyenv version-name)"
        pyenv deactivate || true
    fi
fi

# **Check if Python version is installed**
if ! pyenv versions --bare | grep -q "^$PYTHON_VERSION$"; then
    echo "Installing Python $PYTHON_VERSION..."
    pyenv install "$PYTHON_VERSION"
else
    echo "Python $PYTHON_VERSION is already installed."
fi

# Clone the repository (fresh copy)
if [ -d "$REPO_NAME" ]; then
    echo "Removing existing repository: $REPO_NAME..."
    rm -rf "$REPO_NAME"
fi
echo "Cloning repository: $GIT_URL..."
git clone "$GIT_URL"

# Navigate to the repository
cd "$REPO_NAME"

# Set Python version locally for this project
echo "Setting local Python version to $PYTHON_VERSION for this project..."
pyenv local "$PYTHON_VERSION"

# **Virtual Environment Creation**
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Using native Python venv on Windows..."
    python -m venv "$VENV_NAME"
else
    # Ensure a fresh virtual environment using pyenv-virtualenv (Only for macOS/Linux)
    if pyenv virtualenvs --bare | grep -q "^$VENV_NAME$"; then
        echo "Virtual environment $VENV_NAME already exists. Removing it..."
        pyenv virtualenv-delete -f "$VENV_NAME"
    fi
    echo "Creating new virtual environment: $VENV_NAME with Python $PYTHON_VERSION..."
    pyenv virtualenv "$PYTHON_VERSION" "$VENV_NAME"
fi

# **Deactivate any existing virtual environment**
if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "Deactivating current virtual environment..."
    pyenv deactivate || source deactivate || true
fi

# **Activate Virtual Environment**
echo "Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    source "$VENV_NAME/Scripts/activate"
else
    pyenv local "$VENV_NAME"
    pyenv activate "$VENV_NAME"
fi

# **Fix pip upgrade issue in Windows**
echo "Upgrading pip and setuptools..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    "$VENV_NAME/Scripts/python.exe" -m pip install --upgrade pip setuptools
else
    pip install --upgrade pip setuptools
fi

# Checkout the specified commit
git fetch
git checkout "$COMMIT_HASH"
echo "Repository is now at commit $COMMIT_HASH."

# Install repo in editable mode
echo "Installing repository in editable mode..."
pip install -e .

# Print confirmation details
echo "Current Python version: $(python --version)"
echo "Current pip version: $(pip --version)"
echo "Virtual environment activated successfully."

# Keep the environment activated at the end
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "To continue using the virtual environment, run: source $VENV_NAME/Scripts/activate"
    exec bash --rcfile <(echo "source $VENV_NAME/Scripts/activate")  # Ensures the environment stays activated
else
    exec $SHELL
fi
