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
import random
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
CODE_QUALITY_INITIAL_SCORE = 100.0

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
        'llm_rotation_strategy': LLM_ROTATION_FIXED,
        'bug_checker_hallucination_rate': '0.1',
        'bug_fixer_failure_rate': '0.05',
        'enable_refactoring': 'True',
        'enable_performance_check': 'True',
        'enable_documentation_check': 'True',
        'code_quality_long_line_penalty': '0.5',
        'code_quality_missing_docstring_penalty': '2.0',
        'code_quality_missing_comment_penalty': '1.0',
        'performance_threshold_time': '1.0', # seconds - simulated
        'performance_threshold_memory': '100', # MB - simulated
    },
    'LLM': {
        'llm_model_generation': 'MockLLMGenerate',
        'llm_model_bug_checking': 'MockLLMBugCheck1,MockLLMBugCheck2,MockLLMBugCheckLogic',
        'llm_model_fixing': 'MockLLMFix',
        'llm_model_refactoring': 'MockLLMRefactor',
        'llm_model_performance_check': 'MockLLMPerformanceCheck',
        'llm_model_documentation_check': 'MockLLMDocumentation',
    }
}

# --- Logging Setup ---
class DatabaseHandler(logging.Handler):
    def __init__(self, db_path: str):
        super().__init__()
        self.db_path = db_path

    def emit(self, record: logging.LogRecord):
        async def insert_log():
            try:
                async with aiosqlite.connect(self.db_path) as db:
                    await db.execute(
                        "INSERT INTO logs (level, message, timestamp) VALUES (?, ?, ?)",
                        (record.levelname, self.format(record), record.asctime),
                    )
                    await db.commit()
            except Exception as e:
                print(f"Error logging to database: {e}") # fallback if db logging fails
        asyncio.create_task(insert_log())

async def setup_logging(db_path: str) -> logging.Logger:
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

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
        return None

    async def check_performance(self, code: str) -> Optional[str]:
        return None

    async def check_documentation(self, code: str) -> Optional[str]:
        return None

# --- Mock LLM Implementations ---
class MockLLMGenerate(BaseLLM):
    def __init__(self, call_timeout: float):
        super().__init__("MockLLMGenerate", call_timeout)

    async def generate(self, prompt: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        if "add two numbers" in prompt:
            return """
def add(x, y):
    \"\"\"Adds two numbers.\"\"\"
    return x + y
"""
        elif "subtract" in prompt:
            return """
def subtract(x, y):
    \"\"\"Subtracts y from x.\"\"\"
    return x - y
"""
        elif "calculate area of circle" in prompt:
            return """
import math

def circle_area(radius):
    \"\"\"Calculates the area of a circle.\"\"\"
    return math.pi * radius * radius
"""
        elif "read file" in prompt:
            return """
def read_first_line(filepath):
    \"\"\"Reads the first line of a file.\"\"\"
    try:
        with open(filepath, 'r') as f:
            return f.readline().strip()
    except FileNotFoundError:
        return "File not found."
"""
        else:
            return """
def hello_world():
    \"\"\"Prints hello world\"\"\"
    print('Hello, world!')
"""

    async def check_bugs(self, code: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

class MockLLMBugCheck1(BaseLLM): # Indentation, Docstrings
    def __init__(self, call_timeout: float, hallucination_rate: float = 0.0):
        super().__init__("MockLLMBugCheck1", call_timeout)
        self.hallucination_rate = hallucination_rate

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

    async def check_bugs(self, code: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        bugs = []
        lines = code.splitlines()
        if random.random() < self.hallucination_rate:
            bugs.append(f"Line {random.randint(1, len(lines))}: Spurious indentation bug!")
        for i, line in enumerate(lines):
            if i == 0 and lines[1].strip() and not lines[1].strip().startswith('"""'):
                bugs.append(f"Line {i + 2}: Missing docstring. Severity: Minor")
            if line.startswith("  return") or line.startswith("   return"):
                bugs.append(f"Line {i + 1}: Inconsistent indentation. Severity: Major")
        return "\n".join(bugs) if bugs else ""

class MockLLMBugCheck2(BaseLLM): # Logic, Output, Type
    def __init__(self, call_timeout: float, hallucination_rate: float = 0.0):
        super().__init__("MockLLMBugCheck2", call_timeout)
        self.hallucination_rate = hallucination_rate

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

    async def check_bugs(self, code: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        bugs = []
        lines = code.splitlines()
        if random.random() < self.hallucination_rate:
            bugs.append(f"Line {random.randint(1, len(lines))}: False logic error detected!")
        for i, line in enumerate(lines):
            if "print(" not in code and "return" not in line.lower() and  "def" not in line and line.strip():
                bugs.append(f"Line {len(lines)}: Missing output (print or return). Severity: Minor")
            if "def " in line:
                match = re.search(r"def\s+(\w+)\(", line)
                if match and "circle_area" not in code: # specific to avoid false positive in circle example.
                    function_name = match.group(1)
                    if not any(f"{function_name}(" in l for l in lines if l != line):
                        bugs.append(f"Line {i + 1}: Function '{function_name}' defined but not called. Severity: Info")
            if "radius" in code and "circle_area" in code and "int radius" not in code and "float radius" not in code:
                bugs.append(f"Line ?: Consider type hinting radius to int or float. Severity: Info")
        return "\n".join(bugs) if bugs else ""

class MockLLMBugCheckLogic(BaseLLM): # Deeper Logic checks
    def __init__(self, call_timeout: float, hallucination_rate: float = 0.0):
        super().__init__("MockLLMBugCheckLogic", call_timeout)
        self.hallucination_rate = hallucination_rate

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

    async def check_bugs(self, code: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        bugs = []
        lines = code.splitlines()
        if random.random() < self.hallucination_rate:
            bugs.append(f"Line {random.randint(1, len(lines))}: Phantom logic flaw detected!")

        if "calculate_area" in code:
            if "if length <= 0 or width <= 0:" not in code:
                bugs.append(f"Line ?: Missing input validation for calculate_area (non-positive inputs). Severity: Major")
        if "circle_area" in code:
             if "radius <= 0" not in code and "if radius <=0" not in code:
                bugs.append(f"Line ?: Missing input validation for circle_area (non-positive radius). Severity: Major")
        if "read_first_line" in code:
            if "FileNotFoundError" not in code:
                bugs.append(f"Line ?: Missing exception handling for FileNotFoundError in read_first_line. Severity: Major")
        return "\n".join(bugs) if bugs else ""


class MockLLMFix(BaseLLM):
    def __init__(self, call_timeout: float, failure_rate: float = 0.0):
        super().__init__("MockLLMFix", call_timeout)
        self.failure_rate = failure_rate

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def check_bugs(self, code: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        if random.random() < self.failure_rate:
            logging.warning(f"{self.name} failed to fix all bugs (simulated failure)!")
            return code

        fixed_code = code
        lines = fixed_code.splitlines()
        bugs_list = bug_report.splitlines()
        random.shuffle(bugs_list) # try to fix in random order to simulate real LLM.

        for bug in bugs_list:
            match = re.match(r"Line (\d+|[?]): (.*?)(?: Severity: (\w+))?$", bug) # added Severity group
            if match:
                line_num_str = match.group(1)
                description = match.group(2)
                severity = match.group(3) # can be None

                if line_num_str != '?' and  0 <= int(line_num_str) -1 < len(lines): # valid line number
                    line_num = int(line_num_str) - 1
                else:
                    line_num = -1 # Indicate line number is unknown or not applicable.

                if "Missing docstring" in description and line_num != -1 :
                    lines.insert(line_num, '    """Generated docstring."""')
                    fixed_code = "\n".join(lines)
                elif "Inconsistent indentation" in description and line_num != -1:
                    lines[line_num] = "    " + lines[line_num].lstrip()
                    fixed_code = "\n".join(lines)
                elif "Missing output" in description and line_num != -1:
                    if "add(" in code: # very specific for add function.
                        lines.append("    print('Result:', add(5, 3))")
                    elif "subtract(" in code:
                         lines.append("    print('Result:', subtract(10, 3))")
                    elif "circle_area(" in code:
                         lines.append("    print('Circle Area:', circle_area(7))")
                    else:
                        lines.append("    print('Output:')") # generic output if function unclear.
                    fixed_code = "\n".join(lines)
                elif "Function" in description and "defined but not called" in description and line_num != -1:
                    match_func = re.search(r"Function '(\w+)'", description)
                    if match_func:
                        func_name = match_func.group(1)
                        func_def = [l for l in lines if f"def {func_name}("]
                        if func_def:
                            param_match = re.search(r'\((.*?)\)', func_def[0])
                            if param_match:
                                params = param_match.group(1).split(',')
                                params = [p.strip() for p in params]
                                lines.append(f"    print('{func_name} result:', {func_name}({', '.join(['0'] * len(params))}))")
                                fixed_code = "\n".join(lines)
                elif "Missing input validation for calculate_area" in description:
                    validation_code = """
    if length <= 0 or width <= 0:
        raise ValueError("Length and width must be positive values.")
"""
                    function_def_index = next((i for i,line in enumerate(lines) if "def calculate_area" in line), -1)
                    if function_def_index != -1:
                         lines.insert(function_def_index + 1, validation_code)
                         fixed_code = "\n".join(lines)
                elif "Missing input validation for circle_area" in description:
                    validation_code = """
    if radius <= 0:
        raise ValueError("Radius must be a positive value.")
"""
                    function_def_index = next((i for i,line in enumerate(lines) if "def circle_area" in line), -1)
                    if function_def_index != -1:
                         lines.insert(function_def_index + 1, validation_code)
                         fixed_code = "\n".join(lines)
                elif "FileNotFoundError" in description:
                    exception_handling = """
    except FileNotFoundError:
        return "Error: File not found."
"""
                    try_block_start_index = next(i for i,line in enumerate(lines) if "try:" in line)
                    lines.insert(try_block_start_index + 1 + lines[try_block_start_index+1:].index("with open("), exception_handling) # place after try and indent.
                    fixed_code = "\n".join(lines)
                elif "Consider type hinting radius" in description:
                    for i, line in enumerate(lines):
                        if "def circle_area(radius):" in line:
                            lines[i] = line.replace("radius)", "radius: float)") # simple type hint.
                            fixed_code = "\n".join(lines)
                            break # only type hint first occurence.
        return fixed_code

class MockLLMRefactor(BaseLLM):
    def __init__(self, call_timeout: float):
        super().__init__("MockLLMRefactor", call_timeout)

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def check_bugs(self, code: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

    async def refactor(self, code: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        suggestions = []
        lines = code.splitlines()

        if len(lines) > 8:
            suggestions.append("Refactor: Function is getting long, consider breaking it down.")
        if any(len(line) > 100 for line in lines):
            suggestions.append("Refactor: Line length exceeds 100 characters, improve readability.")
        if "magic number" not in code.lower() and any(re.search(r'\b\d+\b', line) for line in lines) : # very basic magic number check
            suggestions.append("Refactor: Consider replacing magic numbers with named constants for clarity.")
        return "\n".join(suggestions) if suggestions else ""

class MockLLMPerformanceCheck(BaseLLM):
    def __init__(self, call_timeout: float, performance_threshold_time: float, performance_threshold_memory: int):
        super().__init__("MockLLMPerformanceCheck", call_timeout)
        self.performance_threshold_time = performance_threshold_time
        self.performance_threshold_memory = performance_threshold_memory

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def check_bugs(self, code: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_documentation(self, code: str) -> Optional[str]: return None

    async def check_performance(self, code: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        performance_issues = []
        # Simulate performance testing - very basic. In real app, run actual tests.
        start_time = time.time()
        # simulate code execution time.
        await asyncio.sleep(random.uniform(0.1, self.performance_threshold_time * 1.5)) # simulate execution time
        execution_time = time.time() - start_time
        memory_usage = random.randint(50, self.performance_threshold_memory + 50) # simulate memory usage

        if execution_time > self.performance_threshold_time:
            performance_issues.append(f"Performance: Execution time ({execution_time:.2f}s) exceeds threshold ({self.performance_threshold_time}s).")
        if memory_usage > self.performance_threshold_memory:
            performance_issues.append(f"Performance: Memory usage ({memory_usage}MB) exceeds threshold ({self.performance_threshold_memory}MB).")

        return "\n".join(performance_issues) if performance_issues else ""

class MockLLMDocumentation(BaseLLM):
    def __init__(self, call_timeout: float):
        super().__init__("MockLLMDocumentation", call_timeout)

    async def generate(self, prompt: str) -> Optional[str]: return None
    async def check_bugs(self, code: str) -> Optional[str]: return None
    async def fix_bugs(self, code: str, bug_report: str) -> Optional[str]: return None
    async def refactor(self, code: str) -> Optional[str]: return None
    async def check_performance(self, code: str) -> Optional[str]: return None

    async def check_documentation(self, code: str) -> Optional[str]:
        await asyncio.sleep(self.call_timeout)
        documentation_issues = []
        lines = code.splitlines()

        function_defs = [line for line in lines if line.strip().startswith("def ")]
        for func_def in function_defs:
            func_name_match = re.search(r"def\s+(\w+)\(", func_def)
            if func_name_match:
                func_name = func_name_match.group(1)
                docstring_exists = False
                func_def_index = lines.index(func_def)
                if func_def_index + 1 < len(lines) and lines[func_def_index + 1].strip().startswith('"""'):
                    docstring_exists = True
                if not docstring_exists:
                    documentation_issues.append(f"Documentation: Function '{func_name}' is missing a docstring.")
        return "\n".join(documentation_issues) if documentation_issues else ""

# --- LLM Instance and List Retrieval ---
def get_llm_instance(llm_model_name: str, config: configparser.ConfigParser) -> BaseLLM:
    call_timeout = float(config['General']['llm_call_timeout'])
    performance_threshold_time = float(config['General']['performance_threshold_time'])
    performance_threshold_memory = int(config['General']['performance_threshold_memory'])
    hallucination_rate = float(config['General']['bug_checker_hallucination_rate'])
    bug_fixer_failure_rate = float(config['General']['bug_fixer_failure_rate'])

    if llm_model_name == "MockLLMGenerate": return MockLLMGenerate(call_timeout)
    elif llm_model_name == "MockLLMBugCheck1": return MockLLMBugCheck1(call_timeout, hallucination_rate)
    elif llm_model_name == "MockLLMBugCheck2": return MockLLMBugCheck2(call_timeout, hallucination_rate)
    elif llm_model_name == "MockLLMBugCheckLogic": return MockLLMBugCheckLogic(call_timeout, hallucination_rate)
    elif llm_model_name == "MockLLMFix": return MockLLMFix(call_timeout, bug_fixer_failure_rate)
    elif llm_model_name == "MockLLMRefactor": return MockLLMRefactor(call_timeout)
    elif llm_model_name == "MockLLMPerformanceCheck": return MockLLMPerformanceCheck(call_timeout, performance_threshold_time, performance_threshold_memory)
    elif llm_model_name == "MockLLMDocumentation": return MockLLMDocumentation(call_timeout)
    else: raise ValueError(f"Unknown LLM model: {llm_model_name}")

def get_llm_list(llm_model_names: str, config: configparser.ConfigParser) -> List[BaseLLM]:
    return [get_llm_instance(name.strip(), config) for name in llm_model_names.split(',')]

# --- Docker Sandboxing ---
async def run_code_in_docker(code: str, docker_timeout: int, image_name: str) -> bool:
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
            if 'stream' in log: logging.info(log['stream'].strip())

        container = client.containers.run(
            image, volumes={temp_file_path: {'bind': '/app/code.py', 'mode': 'ro'}},
            remove=True, detach=True,
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
            if 'stream' in log: logging.error(log['stream'].strip())
        return False
    except docker.errors.APIError as e:
        logging.error(f"Docker API error: {e}")
        return False
    except Exception as e:
        logging.error(f"Error running code in Docker: {e}")
        return False
    finally:
        if 'temp_file_path' in locals() and os.path.exists(temp_file_path): os.remove(temp_file_path)
        if 'dockerfile_path' in locals() and os.path.exists(dockerfile_path): os.remove(dockerfile_path)

# --- Database Initialization & Interaction ---
async def init_db(db_path: str):
    async with aiosqlite.connect(db_path) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS configurations (
                id INTEGER PRIMARY KEY AUTOINCREMENT, config_name TEXT UNIQUE, config_value TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS code_versions (
                id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INTEGER, code TEXT, quality_score REAL,
                complexity_score REAL, performance_score REAL, documentation_score REAL
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS bug_reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INTEGER, report TEXT, check_number INTEGER,
                llm_name TEXT, severity TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT, level TEXT, message TEXT, timestamp TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS llms (
                id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, type TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS refactorings (
                id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INTEGER, suggestions TEXT, llm_name TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS performance_checks (
                id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INTEGER, report TEXT, llm_name TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS documentation_checks (
                id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INTEGER, report TEXT, llm_name TEXT
            )""")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS complexity_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT, iteration INTEGER, cyclomatic_complexity REAL,
                halstead_volume REAL
            )""")
        await db.commit()

async def store_config(db_path: str, config: configparser.ConfigParser):
    async with aiosqlite.connect(db_path) as db:
        for section, options in config.items():
            for option, value in options.items():
                await db.execute(
                    "INSERT OR REPLACE INTO configurations (config_name, config_value) VALUES (?, ?)",
                    (f"{section}.{option}", value),
                )
        await db.commit()

async def store_code_version(db_path: str, iteration: int, code: str, quality_score: Optional[float],
                           complexity_score: Optional[float], performance_score: Optional[float], documentation_score: Optional[float]):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO code_versions (iteration, code, quality_score, complexity_score, performance_score, documentation_score) VALUES (?, ?, ?, ?, ?, ?)",
            (iteration, code, quality_score, complexity_score, performance_score, documentation_score),
        )
        await db.commit()

async def store_bug_report(db_path: str, iteration: int, report: str, check_number: int, llm_name: str, severity: Optional[str]):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO bug_reports (iteration, report, check_number, llm_name, severity) VALUES (?, ?, ?, ?, ?)",
            (iteration, report, check_number, llm_name, severity),
        )
        await db.commit()

async def store_llm(db_path: str, name: str, llm_type: str):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT OR IGNORE INTO llms (name, type) VALUES (?, ?)",
            (name, llm_type),
        )
        await db.commit()

async def store_refactoring(db_path: str, iteration: int, suggestions: str, llm_name: str):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO refactorings (iteration, suggestions, llm_name) VALUES (?, ?, ?)",
            (iteration, suggestions, llm_name),
        )
        await db.commit()

async def store_performance_check(db_path: str, iteration: int, report: str, llm_name: str):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO performance_checks (iteration, report, llm_name) VALUES (?, ?, ?)",
            (iteration, report, llm_name),
        )
        await db.commit()

async def store_documentation_check(db_path: str, iteration: int, report: str, llm_name: str):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO documentation_checks (iteration, report, llm_name) VALUES (?, ?, ?)",
            (iteration, report, llm_name),
        )
        await db.commit()

async def store_complexity_metrics(db_path: str, iteration: int, cyclomatic_complexity: float, halstead_volume: float):
    async with aiosqlite.connect(db_path) as db:
        await db.execute(
            "INSERT INTO complexity_metrics (iteration, cyclomatic_complexity, halstead_volume) VALUES (?, ?, ?)",
            (iteration, cyclomatic_complexity, halstead_volume),
        )
        await db.commit()

# --- Code Quality, Complexity, Performance, Documentation Metrics ---
def calculate_code_quality(code: str, config: configparser.ConfigParser) -> float:
    score = CODE_QUALITY_INITIAL_SCORE
    lines = code.splitlines()
    for line in lines:
        if len(line) > 80:
            score -= float(config['General']['code_quality_long_line_penalty'])
    if len(lines) > 1 and not lines[1].strip().startswith('"""'):
        score -= float(config['General']['code_quality_missing_docstring_penalty'])
    if not any("#" in line for line in lines):
        score -= float(config['General']['code_quality_missing_comment_penalty'])
    return max(0.0, min(score, CODE_QUALITY_INITIAL_SCORE))

def calculate_cyclomatic_complexity(code: str) -> float: # very basic approximation
    return code.count("if ") + code.count("for ") + code.count("while ") + 1.0

def calculate_halstead_volume(code: str) -> float: # placeholder - more complex in reality.
    return len(code) * 2.0 # very rough approximation.

# --- LLM Rotation Strategy ---
def get_next_bug_checker(current_llms: List[BaseLLM], strategy: str, current_index: int = 0) -> Tuple[BaseLLM, int]:
    if not current_llms: raise ValueError("No bug checking LLMs provided.")
    if strategy == LLM_ROTATION_FIXED: return current_llms[0], 0
    elif strategy == LLM_ROTATION_RANDOM: return random.choice(current_llms), 0
    elif strategy == LLM_ROTATION_ROUND_ROBIN:
        next_index = (current_index + 1) % len(current_llms)
        return current_llms[next_index], next_index
    else: raise ValueError(f"Invalid LLM rotation strategy: {strategy}")

# --- Main Application Logic ---
async def main(config_file: Optional[str], initial_prompt: str, feature_request: Optional[str]) -> int:
    config = configparser.ConfigParser()
    config.read_dict(DEFAULT_CONFIG)
    if config_file: config.read(config_file)

    db_path = config['General']['database_file']
    iteration_limit = int(config['General']['iteration_limit'])
    feature_addition_round = int(config['General']['feature_addition_round'])
    docker_timeout = int(config['General']['docker_timeout'])
    docker_image_name = config['General']['docker_image_name']
    bug_checks_per_iteration = int(config['General']['bug_checks_per_iteration'])
    llm_rotation_strategy = config['General']['llm_rotation_strategy']
    enable_refactoring = config['General']['enable_refactoring'] == 'True'
    enable_performance_check = config['General']['enable_performance_check'] == 'True'
    enable_documentation_check = config['General']['enable_documentation_check'] == 'True'

    await init_db(db_path)
    logger = await setup_logging(db_path)
    await store_config(db_path, config)

    generate_llm = get_llm_instance(config['LLM']['llm_model_generation'], config)
    bug_check_llms = get_llm_list(config['LLM']['llm_model_bug_checking'], config)
    fix_llm = get_llm_instance(config['LLM']['llm_model_fixing'], config)
    refactor_llm = get_llm_instance(config['LLM']['llm_model_refactoring'], config)
    performance_llm = get_llm_instance(config['LLM']['llm_model_performance_check'], config)
    documentation_llm = get_llm_instance(config['LLM']['llm_model_documentation_check'], config)

    await store_llm(db_path, generate_llm.name, "generation")
    for llm in bug_check_llms: await store_llm(db_path, llm.name, "bug_checking")
    await store_llm(db_path, fix_llm.name, "fixing")
    await store_llm(db_path, refactor_llm.name, "refactoring")
    await store_llm(db_path, performance_llm.name, "performance_check")
    await store_llm(db_path, documentation_llm.name, "documentation_check")

    code = await generate_llm.generate(initial_prompt)
    if not code:
        logger.error("Initial code generation failed.")
        return EXIT_FAILURE

    bug_checker_index = 0

    for i in range(iteration_limit):
        logger.info(f"--- Iteration: {i + 1} ---")
        logger.info(f"Current Code:\n{code}")

        quality_score = calculate_code_quality(code, config)
        complexity_score = calculate_cyclomatic_complexity(code)
        halstead_volume = calculate_halstead_volume(code)
        await store_code_version(db_path, i + 1, code, quality_score, complexity_score, None, None) # perf and doc scores updated later.
        await store_complexity_metrics(db_path, i+1, complexity_score, halstead_volume)
        logger.info(f"Code Quality Score: {quality_score:.2f}, Complexity: {complexity_score:.2f}, Halstead Volume: {halstead_volume:.2f}")

        for check_num in range(bug_checks_per_iteration):
            bug_checker, bug_checker_index = get_next_bug_checker(bug_check_llms, llm_rotation_strategy, bug_checker_index)
            logger.info(f"Using bug checker: {bug_checker.name} (Check {check_num + 1})")

            bug_report = await bug_checker.check_bugs(code)
            if bug_report:
                logger.info(f"Bug Report:\n{bug_report}")
                # basic severity parsing from bug report.
                severity = "Unknown"
                if "Severity: Major" in bug_report: severity = "Major"
                elif "Severity: Minor" in bug_report: severity = "Minor"
                elif "Severity: Info" in bug_report: severity = "Info"
                await store_bug_report(db_path, i + 1, bug_report, check_num + 1, bug_checker.name, severity)
                code = await fix_llm.fix_bugs(code, bug_report)
                if not code:
                    logger.error("Bug fixing failed. Stopping.")
                    return EXIT_FAILURE

        if enable_performance_check:
            logger.info("Running performance check...")
            performance_report = await performance_llm.check_performance(code)
            performance_score_val = 100.0 if not performance_report else 50.0 # very basic score.
            await store_performance_check(db_path, i+1, performance_report or "No performance issues detected.", performance_llm.name)
            await store_code_version(db_path, i + 1, code, quality_score, complexity_score, performance_score_val, None) # update score again.
            if performance_report: logger.info(f"Performance Report:\n{performance_report}")
            logger.info(f"Performance Score: {performance_score_val:.2f}")


        if enable_documentation_check:
            logger.info("Running documentation check...")
            documentation_report = await documentation_llm.check_documentation(code)
            documentation_score_val = 100.0 if not documentation_report else 70.0 # very basic score.
            await store_documentation_check(db_path, i+1, documentation_report or "Documentation check passed.", documentation_llm.name)
            await store_code_version(db_path, i + 1, code, quality_score, complexity_score, performance_score_val, documentation_score_val) # update score again
            if documentation_report: logger.info(f"Documentation Report:\n{documentation_report}")
            logger.info(f"Documentation Score: {documentation_score_val:.2f}")


        if enable_refactoring:
            logger.info("Running refactoring...")
            refactoring_suggestions = await refactor_llm.refactor(code)
            if refactoring_suggestions:
                logger.info(f"Refactoring Suggestions:\n{refactoring_suggestions}")
                await store_refactoring(db_path, i+1, refactoring_suggestions, refactor_llm.name)

        if (i + 1) == feature_addition_round and feature_request:
            logger.info("Adding Feature...")
            code = await generate_llm.generate(feature_request)
            if not code:
                logger.error("Feature addition failed. Continuing without it.")

        try:
            docker.from_env()
            if not await run_code_in_docker(code, docker_timeout, docker_image_name):
                logger.info("Code execution had errors in Docker.") # changed to info, execution errors are expected.
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
    parser.add_argument("-d", "--database_file", type=str, default=None, help="Path to the output database file (.db)")

    args = parser.parse_args()
    if args.database_file:
        DEFAULT_CONFIG['General']['database_file'] = args.database_file

    exit_code = asyncio.run(main(args.config_file, args.initial_prompt, args.feature_request))
    sys.exit(exit_code)
