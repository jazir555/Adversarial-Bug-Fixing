import asyncio
import logging
import re
import argparse
import tempfile
import os
import docker  # Import the Docker SDK

# --- Configuration (Adjust as needed) ---
ITERATION_LIMIT = 3
FEATURE_ADDITION_ROUND = 2
DOCKER_TIMEOUT = 10  # seconds
DOCKER_IMAGE_NAME = "python-sandbox"  # Name for our Docker image

# Mock LLM Configuration
LLM_MODEL_GENERATION = "mock_llm_gen"
LLM_MODEL_BUG_CHECKING = "mock_llm_bug"
LLM_MODEL_FIXING = "mock_llm_fix"

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Mock LLM Functions (Separated) ---

async def mock_llm_generate(prompt):
    """Simulates LLM code generation."""
    await asyncio.sleep(0.1)
    if "add two numbers" in prompt:
        return """
def add(x, y):
    return x + y
"""  # Initial code (with intentional indentation error)
    elif "subtract" in prompt:
        return """
def add_and_subtract(x, y):
    \"\"\"Adds and subtracts two numbers.\"\"\"
    addition = x + y
    subtraction = x - y
    return addition, subtraction
"""  # Code with feature added
    else:
        return "print('Hello, world!')"

async def mock_llm_bug_check(code, llm_model):
    """Simulates LLM bug detection."""
    await asyncio.sleep(0.1)
    bugs = []
    lines = code.splitlines()
    for i, line in enumerate(lines):
        if i == 1 and not line.strip().startswith('"""'):
            bugs.append(f"Line {i + 1}: Missing docstring.")
        if line.startswith("  return") or line.startswith("   return") :
            bugs.append(f"Line {i + 1}: Inconsistent indentation (should be 4 spaces).")
        if line.startswith(" "):
            if not (line.startswith("    ") or line.startswith("def") or line.startswith("\"\"\"") or line.strip() == ""):
              bugs.append(f"Line {i + 1}: Inconsistent indentation (not 4 spaces).")

    return "\n".join(bugs) if bugs else ""

async def mock_llm_fix(code, bug_report, llm_model):
    """Simulates LLM bug fixing."""
    await asyncio.sleep(0.1)
    fixed_code = code
    lines = fixed_code.splitlines()

    for bug in bug_report.splitlines():
        match = re.match(r"Line (\d+): (.*)", bug)
        if match:
            line_num = int(match.group(1)) - 1
            description = match.group(2)

            if "Missing docstring" in description and 0 <= line_num < len(lines):
                lines.insert(line_num, '    """This function performs an operation."""')
                fixed_code = "\n".join(lines)
            elif "Inconsistent indentation" in description and 0 <= line_num < len(lines):
                lines[line_num] = "    " + lines[line_num].lstrip()
                fixed_code = "\n".join(lines)

    return fixed_code

async def mock_llm_add_feature(code, feature_request, llm_model):
    """Simulates LLM feature addition."""
    return await mock_llm_generate(feature_request)

# --- LLM Function Lookup ---
def get_llm_function(llm_model):
    """Returns the appropriate mock LLM function."""
    if llm_model == LLM_MODEL_GENERATION:
        return mock_llm_generate
    elif llm_model == LLM_MODEL_BUG_CHECKING:
        return mock_llm_bug_check
    elif llm_model == LLM_MODEL_FIXING:
        return mock_llm_fix
    else:
        raise ValueError(f"Unknown LLM model: {llm_model}")

async def run_code_in_docker(code):
    """Runs the given Python code inside a Docker container."""
    try:
        client = docker.from_env()  # Create a Docker client
        # Create a temporary file for the code
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=".py") as temp_file:
            temp_file.write(code)
            temp_file_path = temp_file.name

        # Define dockerfile content.
        dockerfile_content = f"""
FROM python:3.9-slim-buster
WORKDIR /app
CMD ["python", "code.py"]
"""
        # create dockerfile
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix="Dockerfile") as df:
            df.write(dockerfile_content)
            dockerfile_path = df.name

        # Build the Docker image
        image, build_logs = client.images.build(
            path=os.path.dirname(dockerfile_path),
            dockerfile=os.path.basename(dockerfile_path),
            tag=DOCKER_IMAGE_NAME,
            rm=True  # Remove intermediate containers after a successful build
        )

        for log in build_logs:  # Print build logs
             if 'stream' in log:
                logging.info(log['stream'].strip())


        # Run the container
        container = client.containers.run(
            image,
            volumes={temp_file_path: {'bind': '/app/code.py', 'mode': 'ro'}},  # Mount the code file
            remove=True,  # Automatically remove the container when it exits
            detach=True, # Run in detached mode
        )
        try:
            # Wait for container to finish, with timeout.
            result = container.wait(timeout=DOCKER_TIMEOUT)
            exit_code = result['StatusCode']
            success = (exit_code == 0)
        except (TimeoutError, docker.errors.APIError) as e:
            logging.error(f"Docker container error: {e}")
            container.stop()
            success = False

        # Get the container logs
        logs = container.logs(stdout=True, stderr=True).decode('utf-8')
        logging.info(f"Docker Container Logs:\n{logs}")

        return success

    except docker.errors.BuildError as e:
        logging.error(f"Docker build failed: {e}")
        for log in e.build_log:
            if 'stream' in log:
                logging.error(log['stream'].strip())
        return False
    except docker.errors.APIError as e:
        logging.error(f"Docker API error: {e}")
        return False
    except Exception as e:
        logging.error(f"Error running code in Docker: {e}")
        return False
    finally:
        # Clean up
        if 'temp_file_path' in locals() and os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        if 'dockerfile_path' in locals() and os.path.exists(dockerfile_path):
            os.remove(dockerfile_path)

async def main(initial_prompt, feature_request):
    """Main loop for the adversarial bug testing system."""
    generate_func = get_llm_function(LLM_MODEL_GENERATION)
    bug_check_func = get_llm_function(LLM_MODEL_BUG_CHECKING)
    fix_func = get_llm_function(LLM_MODEL_FIXING)

    code = await generate_func(initial_prompt)
    if not code:
        logging.error("Initial code generation failed.")
        return

    bug_reports = []
    for i in range(ITERATION_LIMIT):
        logging.info(f"--- Iteration: {i + 1} ---")
        logging.info(f"Current Code:\n{code}")

        # Bug Checking
        bug_report = await bug_check_func(code, LLM_MODEL_BUG_CHECKING)
        if bug_report:
            bug_reports.append(f"Iteration {i+1}: {bug_report}")
            logging.info(f"Bug Report:\n{bug_report}")

            # Fix Bugs
            code = await fix_func(code, bug_report, LLM_MODEL_FIXING)
            if not code:
                logging.error("Bug fixing failed. Stopping.")
                return

        # Add Feature
        if (i + 1) == FEATURE_ADDITION_ROUND and feature_request:
            logging.info("Adding Feature...")
            code = await mock_llm_add_feature(code, feature_request, LLM_MODEL_FIXING)
            if not code:
                logging.error("Feature addition failed. Continuing without it.")

        # Run Code and Log Errors (in Docker)
        try:
            docker.from_env()  # Check if docker is available
            if not await run_code_in_docker(code):
                 logging.info("Code execution had errors.")
        except docker.errors.DockerException:
            logging.warning("Docker is not available. Skipping code execution.")


    logging.info("--- Adversarial Bug Testing Complete ---")
    logging.info(f"Final Code:\n{code}")
    logging.info(f"All Bug Reports:\n{chr(10).join(bug_reports)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Adversarial Bug Testing System")
    parser.add_argument("initial_prompt", type=str, help="Initial prompt for code generation")
    parser.add_argument("-f", "--feature_request", type=str, default=None, help="Feature request to be added")
    args = parser.parse_args()

    asyncio.run(main(args.initial_prompt, args.feature_request))
