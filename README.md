# **Project Setup Script - README** 🚀

## **Overview**
This script automates the entire setup process for setting up the task, making it easy to get started. It handles the following tasks:

- ✅ **Installs Python** (via `pyenv`) if not already installed  
- ✅ **Creates and activates a virtual environment in the same terminal after execution**  
- ✅ **Fetches the Git repository** and checks out a specific commit  
- ✅ **Installs dependencies in editable mode** (`pip install -e .`)  
- ✅ **Ensures the environment is activated after the script completes**  
- ✅ **Removes the old virtual environment and repository if needed** (for a fresh setup)  
- ✅ **Allows switching to a new repository** with ease  

**Tested on both Windows & macOS** 🎯  
** NOTE: For Windows use git bash
For any task, just run the script, and everything will be ready to work! 🚀  

---

## **Usage**
Run the script with the required arguments:

```bash
bash local_setup.sh PYTHON_VERSION ENV_NAME GIT_URL COMMIT_HASH
```

### **Example**
```bash
bash local_setup.sh 3.7 my_new_env https://github.com/pydata/xarray.git e56905889c836c736152b11a7e6117a229715975
```

This will:
1. Install Python `3.7` (if not installed)
2. Remove any existing virtual environment and repository (for a fresh start)
3. Create and activate a virtual environment (`my_new_env`)
4. Clone the `xarray` repository
5. Checkout the commit `e56905889c836c736152b11a7e6117a229715975`
6. Install the project in editable mode

---

