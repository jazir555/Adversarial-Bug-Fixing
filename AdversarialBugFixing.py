import asyncio
import logging
import re
import argparse
import tempfile
import os
import docker
import aiosqlite
import configparser
import time
import sys
import random  # For random LLM selection
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Tuple, Union, Callable

# --- Exit Codes ---
EXIT_SUCCESS = 0
EXIT_FAILURE = 1
EXIT_DOCKER_UNAVAILABLE = 2

# --- Constants ---
LLM_ROTATION_FIXED = "fixed"
LLM_ROTATION_RANDOM = "random"
LLM_ROTATION_ROUND_ROBIN = "round_robin"

DEFAULT_DOCKERFILE_CONTENT = """
FROM python:3.9-slim-buster
WORKDIR /app
CMD ["python", "code.py"]
"""

# --- Configuration ---
DEFAULT_CONFIG = {
    'General': {
        'iteration_limit': '3',
        'feature_addition_round': '2',
        'docker_timeout': '10',
        'docker_image_name': 'python-sandbox',
        'database_file': 'adversarial_testing.db',
        'llm_call_timeout': '5',
        'bug_checks_per_iteration': '2',
        'llm_rotation_strategy': LLM_ROTATION_FIXED,  # fixed, random, round_robin
        'bug_checker_hallucination_rate': '0.1',  # 10% chance of false positive
        'bug_fixer_failure_rate': '0.05',        # 5% chance of failing to fix
        'enable_refactoring': 'True',           # Whether to include the refactoring stage
    },
    'LLM': {
        'llm_model_generation': 'MockLLMGenerate',
        'llm_model_bug_checking': 'MockLLMBugCheck1,MockLLMBugCheck2',  # Comma-separated list
        'llm_model_fixing': 'MockLLMFix',
        'llm_model_refactoring': 'MockLLMRefactor',
    }
}

# --- Logging Setup (Database and Console) ---
class DatabaseHandler(logging.Handler):
    def __init__(self, db_path: str):
        super().__init__()
        self.db_path = db_path

    def emit(self, record: logging.LogRecord):
        async def insert_log():
            async with aiosqlite.connect(self.db_path) as db:
                await db.execute(
                    "INSERT INTO logs (level, message) VALUES (?, ?)",
                    (record.levelname, self.format(record)),
                )
                await db.commit()
        asyncio.create_task(insert_log())

async def setup_logging(db_path: str) -> logging.Logger:
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')

    # Console handler
    ch = logging.StreamHandler()
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    # Database handler
    db_handler = DatabaseHandler(db_path)
    db_handler.setFormatter(formatter)
    logger.addHandler(db_handler)

    return logger


# --- Abstract Base Class for LLMs ---
class BaseLLM(ABC):
    """Abstract base class for all LLMs."""

    def __init__(self, name: str, call_timeout: float):
        self.name = name
        self.call_timeout = call_timeout

    @abstractmethod
    async def generate(self, prompt: str) -> Optional[str]:
        pass

    @abstractmethod
    async def check_bugs(self, code: str) -> Optional[str]:
        pass

    @abstractmethod
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        pass

    async def refactor(self, code: str) -> Optional[str]:
        """Refactors the code (optional).  Default implementation returns None."""
        return None

# --- Mock LLM Implementations ---

class MockLLMGenerate(BaseLLM):
    def __init__(self, call_timeout: float):
        super().__init__("MockLLMGenerate", call_timeout)

    async def generate(self, prompt: str) -> Optional[str]:
        """Simulates LLM code generation."""
        await asyncio.sleep(self.call_timeout)
        if "add two numbers" in prompt:
            return """
def add(x, y):
    return x + y
"""
        elif "subtract" in prompt:
            return """
def add_and_subtract(x, y):
    \"\"\"Adds and subtracts two numbers.\"\"\"
    addition = x + y
    subtraction = x - y
    return addition, subtraction
"""
        elif "calculate area" in prompt:
            return """
def calculate_area(length, width):
    \"\"\"Calculates the area of a rectangle.\"\"\"
    if length <= 0 or width <= 0:
        return "Invalid input: Length and width must be positive."
    return length * width
"""
        else:
            return "print('Hello, world!')"

    async def check_bugs(self, code: str) -> Optional[str]:
        return None  # Not used

    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        return None # Not used

class MockLLMBugCheck1(BaseLLM):
    def __init__(self, call_timeout: float, hallucination_rate: float = 0.0):
        super().__init__("MockLLMBugCheck1", call_timeout)
        self.hallucination_rate = hallucination_rate

    async def generate(self, prompt: str) -> Optional[str]:
        return None

    async def check_bugs(self, code: str) -> Optional[str]:
        """Simulates LLM bug detection (focus on indentation and docstrings)."""
        await asyncio.sleep(self.call_timeout)
        bugs = []
        lines = code.splitlines()

        # Hallucination (false positive)
        if random.random() < self.hallucination_rate:
            bugs.append(f"Line {random.randint(1, len(lines))}: Spurious bug report!")

        for i, line in enumerate(lines):
            if i == 0 and lines[1].strip() and not lines[1].strip().startswith('"""'):
                bugs.append(f"Line {i + 2}: Missing docstring.")
            if line.startswith("  return") or line.startswith("   return"):
                bugs.append(f"Line {i + 1}: Inconsistent indentation (should be 4 spaces).")
        return "\n".join(bugs) if bugs else ""

    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        return None # Not used

class MockLLMBugCheck2(BaseLLM):
    def __init__(self, call_timeout: float, hallucination_rate: float = 0.0):
        super().__init__("MockLLMBugCheck2", call_timeout)
        self.hallucination_rate = hallucination_rate

    async def generate(self, prompt: str) -> Optional[str]:
        return None # Not used

    async def check_bugs(self, code: str) -> Optional[str]:
        """Simulates LLM bug detection (focus on logic and output)."""
        await asyncio.sleep(self.call_timeout)
        bugs = []
        lines = code.splitlines()

        # Hallucination (false positive)
        if random.random() < self.hallucination_rate:
            bugs.append(f"Line {random.randint(1, len(lines))}: Imaginary bug detected!")

        for i, line in enumerate(lines):
            if "print(" not in code :
                bugs.append(f"Line {len(lines)}: Missing print statement to display output.") # check last line
            if "def " in line:
                match = re.search(r"def\s+(\w+)\(", line)
                if match:
                    function_name = match.group(1)
                    if not any(f"{function_name}(" in l for l in lines if l != line):
                        bugs.append(f"Line {i + 1}: Function '{function_name}' is defined but never called.")
            if "if" in line and "else" not in code:
                bugs.append(f"Line {i + 1}: 'if' statement without corresponding 'else'.")

        return "\n".join(bugs) if bugs else ""


    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        return None  # Not used


class MockLLMFix(BaseLLM):
    def __init__(self, call_timeout: float, failure_rate: float = 0.0):
        super().__init__("MockLLMFix", call_timeout)
        self.failure_rate = failure_rate

    async def generate(self, prompt: str) -> Optional[str]:
        return None # Not used

    async def check_bugs(self, code: str) -> Optional[str]:
        return None # Not used

    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        """Simulates LLM bug fixing."""
        await asyncio.sleep(self.call_timeout)

        # Simulate occasional failure to fix
        if random.random() < self.failure_rate:
            logging.warning("MockLLMFix failed to fix all bugs!")
            return code  # Return original code unchanged

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
                elif "Missing print statement" in description and 0 <= line_num < len(lines):
                    lines.append("    print('Result:', add(5, 3))") # Assumes add function.
                    fixed_code = "\n".join(lines)
                elif "Function" in description and "is defined but never called" in description:
                    match = re.search(r"Function '(\w+)'", description)
                    if match:
                        func_name = match.group(1)
                        # Find where are the parameters, and call with default 0 values
                        func_def = [l for l in lines if f"def {func_name}("]
                        if func_def:
                            param_match = re.search(r'\((.*?)\)', func_def[0])  # Use (.*?) to capture only inside parentheses
                            if param_match:
                                params = param_match.group(1).split(',')
                                params = [p.strip() for p in params]  # Remove leading/trailing spaces
                                # Add the function call
                                lines.append(f"    print('{func_name}', {func_name}({', '.join(['0'] * len(params))}))")
                                fixed_code = "\n".join(lines)
                elif "'if' statement without corresponding 'else'" in description:
                    lines.insert(line_num + 1, "    else:\n        pass")
                    fixed_code = "\n".join(lines)


        return fixed_code

class MockLLMRefactor(BaseLLM):
    def __init__(self, call_timeout: float):
        super().__init__("MockLLMRefactor", call_timeout)

    async def generate(self, prompt: str) -> Optional[str]:
        return None # Not used

    async def check_bugs(self, code: str) -> Optional[str]:
        return None # Not used

    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        return None # Not used

    async def refactor(self, code: str) -> Optional[str]:
        """Simulates LLM code refactoring suggestions."""
        await asyncio.sleep(self.call_timeout)
        suggestions = []
        lines = code.splitlines()

        if len(lines) > 5:
            suggestions.append("Consider breaking down long functions into smaller, more manageable units.")
        if any(len(line) > 80 for line in lines):
            suggestions.append("Some lines exceed 80 characters.  Improve readability by keeping lines shorter.")
        if not any("import" in line for line in lines):
            suggestions.append("Consider adding type hints to improve code clarity.")

        return "\n".join(suggestions) if suggestions else ""



# --- LLM Function Lookup ---
def get_llm_instance(llm_model_name: str, config: configparser.ConfigParser) -> BaseLLM:
    """Returns the appropriate mock LLM instance based on the model name."""
    call_timeout = float(config['General']['llm_call_timeout'])
    if llm_model_name == "MockLLMGenerate":
        return MockLLMGenerate(call_timeout)
    elif llm_model_name == "MockLLMBugCheck1":
        hallucination_rate = float(config['General']['bug_checker_hallucination_rate'])
        return MockLLMBugCheck1(call_timeout, hallucination_rate)
    elif llm_model_name == "MockLLMBugCheck2":
        hallucination_rate = float(config['General']['bug_checker_hallucination_rate'])
        return MockLLMBugCheck2(call_timeout, hallucination_rate)
    elif llm_model_name == "MockLLMFix":
        failure_rate = float(config['General']['bug_fixer_failure_rate'])
        return MockLLMFix(call_timeout, failure_rate)
    elif llm_model_name == "MockLLMRefactor":
        return MockLLMRefactor(call_timeout)
    else:
        raise ValueError(f"Unknown LLM model: {llm_model_name}")

def get_llm_list(llm_model_names: str, config: configparser.ConfigParser) -> List[BaseLLM]:
    """Returns a list of LLM instances based on comma-separated model names."""
    return [get_llm_instance(name.strip(), config) for name in llm_model_names.split(',')]


# --- Docker Sandboxing ---

async def run_code_in_docker(code: str, docker_timeout: int, image_name: str) -> bool:
    """Runs the given Python code inside a Docker container."""
    try:
        client = docker.from_env()

        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=".py") as temp_file:
            temp_file.write(code)
            temp_file_path = temp_file.name

        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix="Dockerfile") as df:
            df.write(DEFAULT_DOCKERFILE_CONTENT)
            dockerfile_path = df.name

        image, build_logs = client.images.build(
            path=os.path.dirname(dockerfile_path),
            dockerfile=os.path.basename(dockerfile_path),
            tag=image_name,
            rm=True
        )
        for log in build_logs:
            if 'stream' in log:
                logging.info(log['stream'].strip())

        container = client.containers.run(
            image,
            volumes={temp_file_path: {'bind': '/app/code.py', 'mode': 'ro'}},
            remove=True,
            detach=True,
        )
        try:
            result = container.wait(timeout=docker_timeout)
            exit_code = result['StatusCode']
            success = (exit_code == 0)
        except (TimeoutError, docker.errors.APIError) as e:
            logging.error(f"Docker container error: {e}")
            container.stop()
            success = False

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
        if 'temp_file_path' in locals() and os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        if 'dockerfile_path' in locals() and os.path.exists(dockerfile_path):
            os.remove(dockerfile_path)
# --- Database Initialization ---

async def init_db(db_path: str):
    """Initializes the database."""
    async with aiosqlite.connect(db_path) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS configurations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                config_name TEXT UNIQUE,
                config_value TEXT
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS code_versions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                iteration INTEGER,
                code TEXT,
                quality_score REAL
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS bug_reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                iteration INTEGER,
                report TEXT,
                check_number INTEGER,
                llm_name TEXT
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                level TEXT,
                message TEXT
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS llms (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE,
                type TEXT
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS refactorings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                iteration INTEGER,
                suggestions TEXT,
                llm_name TEXT
            )
        """)

        await db.commit()

# --- Database Interaction Functions ---

async def store_config(db_path: str, config: configparser.ConfigParser):
    """Stores configuration values in the database."""
    async with aiosqlite.connect(db_path) as db:
        for section, options in config.items():
            for option, value in options.items():
                await db.execute(
                    "INSERT OR REPLACE INTO configurations (config_name, config_value) VALUES (?, ?)",
                    (f"{section}.{option}", value),
                )
        await db.commit()

async def store_code_version(db_path: str, iteration: int, code: str, quality_score: Optional[float] = None):
    """Stores a code version in the database."""
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO code_versions (iteration, code, quality_score) VALUES (?, ?, ?)",
            (iteration, code, quality_score),
        )
        await db.commit()

async def store_bug_report(db_path: str, iteration: int, report: str, check_number: int, llm_name: str):
    """Stores a bug report in the database."""
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO bug_reports (iteration, report, check_number, llm_name) VALUES (?, ?, ?, ?)",
            (iteration, report, check_number, llm_name),
        )
        await db.commit()

async def store_llm(db_path: str, name: str, llm_type: str):
    """Stores information about an LLM in the database."""
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT OR IGNORE INTO llms (name, type) VALUES (?, ?)",  # Use IGNORE to avoid duplicates
            (name, llm_type),
        )
        await db.commit()

async def store_refactoring(db_path: str, iteration: int, suggestions: str, llm_name: str):
    """Stores refactoring suggestions in the database."""
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO refactorings (iteration, suggestions, llm_name) VALUES (?, ?, ?)",
            (iteration, suggestions, llm_name),
        )
        await db.commit()

# --- Code Quality Metrics (Simulated) ---
def calculate_code_quality(code: str) -> float:
    """Calculates a simple code quality score (mock implementation)."""
    score = 100.0
    lines = code.splitlines()

    # Deduct points for long lines
    for line in lines:
        if len(line) > 80:
            score -= 0.5

    # Deduct points for missing docstrings (very basic check)
    if len(lines) > 1 and not lines[1].strip().startswith('"""'):
        score -= 2.0

    # Deduct points for lack of comments (very basic)
    if not any("#" in line for line in lines):
        score -= 1.0
    # ensure score is within 0-100
    return max(0.0, min(score, 100.0))

# --- LLM Rotation Strategies ---

def get_next_bug_checker(
    current_llms: List[BaseLLM], strategy: str, current_index: int = 0
) -> Tuple[BaseLLM, int]:
    """Gets the next bug checking LLM based on the selected strategy."""

    if not current_llms:
        raise ValueError("No bug checking LLMs provided.")

    if strategy == LLM_ROTATION_FIXED:
        return current_llms[0], 0  # Always return the first LLM
    elif strategy == LLM_ROTATION_RANDOM:
        return random.choice(current_llms), 0 # new index is not important
    elif strategy == LLM_ROTATION_ROUND_ROBIN:
        next_index = (current_index + 1) % len(current_llms)
        return current_llms[next_index], next_index
    else:
        raise ValueError(f"Invalid LLM rotation strategy: {strategy}")

# --- Main Application Logic ---

async def main(config_file: Optional[str], initial_prompt: str, feature_request: Optional[str]) -> int:
    """Main loop for the adversarial bug testing system."""

    # --- Load Configuration ---
    config = configparser.ConfigParser()
    config.read_dict(DEFAULT_CONFIG)
    if config_file:
        config.read(config_file)

    db_path = config['General']['database_file']
    iteration_limit = int(config['General']['iteration_limit'])
    feature_addition_round = int(config['General']['feature_addition_round'])
    docker_timeout = int(config['General']['docker_timeout'])
    docker_image_name = config['General']['docker_image_name']
    bug_checks_per_iteration = int(config['General']['bug_checks_per_iteration'])
    llm_rotation_strategy = config['General']['llm_rotation_strategy']
    enable_refactoring = config['General']['enable_refactoring'] == 'True'

    # Initialize database and logging
    await init_db(db_path)
    logger = await setup_logging(db_path)
    await store_config(db_path, config)

    # Get LLM instances
    generate_llm = get_llm_instance(config['LLM']['llm_model_generation'], config)
    bug_check_llms = get_llm_list(config['LLM']['llm_model_bug_checking'], config)
    fix_llm = get_llm_instance(config['LLM']['llm_model_fixing'], config) # For now only using one.
    refactor_llm = get_llm_instance(config['LLM']['llm_model_refactoring'], config)

    # Store LLM info in the database
    await store_llm(db_path, generate_llm.name, "generation")
    for llm in bug_check_llms:
        await store_llm(db_path, llm.name, "bug_checking")
    await store_llm(db_path, fix_llm.name, "fixing")
    await store_llm(db_path, refactor_llm.name, "refactoring")

    code = await generate_llm.generate(initial_prompt)
    if not code:
        logger.error("Initial code generation failed.")
        return EXIT_FAILURE

    bug_checker_index = 0  # Index for round-robin strategy

    for i in range(iteration_limit):
        logger.info(f"--- Iteration: {i + 1} ---")
        logger.info(f"Current Code:\n{code}")

        quality_score = calculate_code_quality(code)
        await store_code_version(db_path, i + 1, code, quality_score)
        logger.info(f"Code Quality Score: {quality_score:.2f}")

        # --- Bug Checking (Multiple Checks and LLMs) ---
        for check_num in range(bug_checks_per_iteration):
            bug_checker, bug_checker_index = get_next_bug_checker(
                bug_check_llms, llm_rotation_strategy, bug_checker_index
            )
            logger.info(f"Using bug checker: {bug_checker.name} (Check {check_num + 1})")

            bug_report = await bug_checker.check_bugs(code)
            if bug_report:
                logger.info(f"Bug Report:\n{bug_report}")
                await store_bug_report(db_path, i + 1, bug_report, check_num + 1, bug_checker.name)

                # Fix Bugs
                code = await fix_llm.fix_bugs(code, bug_report)
                if not code:
                    logger.error("Bug fixing failed. Stopping.")
                    return EXIT_FAILURE

        # --- Refactoring Stage ---
        if enable_refactoring:
            logger.info("Running refactoring...")
            refactoring_suggestions = await refactor_llm.refactor(code)
            if refactoring_suggestions:
                logger.info(f"Refactoring Suggestions:\n{refactoring_suggestions}")
                await store_refactoring(db_path, i+1, refactoring_suggestions, refactor_llm.name)

        # --- Feature Addition ---
        if (i + 1) == feature_addition_round and feature_request:
            logger.info("Adding Feature...")
            code = await generate_llm.generate(feature_request)
            if not code:
                logger.error("Feature addition failed. Continuing without it.")

        # --- Run Code and Log Errors (in Docker) ---
        try:
            docker.from_env()
            if not await run_code_in_docker(code, docker_timeout, docker_image_name):
                logger.info("Code execution had errors.")
        except docker.errors.DockerException:
            logging.error("Docker is not available. Skipping code execution.")
            return EXIT_DOCKER_UNAVAILABLE

    logger.info("--- Adversarial Bug Testing Complete ---")
    logger.info(f"Final Code:\n{code}")
    return EXIT_SUCCESS


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Adversarial Bug Testing System")
    parser.add_argument("initial_prompt", type=str, help="Initial prompt for code generation")
    parser.add_argument("-f", "--feature_request", type=str, default=None, help="Feature request to be added")
    parser.add_argument("-c", "--config_file", type=str, default=None, help="Path to the configuration file (.ini)")
    parser.add_argument("-d", "--database_file", type=str, default=None,
                        help="Path to the output database file (.db)")  # Optional

    args = parser.parse_args()

    if args.database_file:
        DEFAULT_CONFIG['General']['database_file'] = args.database_file

    exit_code = asyncio.run(main(args.config_file, args.initial_prompt, args.feature_request))
    sys.exit(exit_code)
