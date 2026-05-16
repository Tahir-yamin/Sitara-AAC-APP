import sys

def read_utf16_last_n(filepath, n=100):
    try:
        with open(filepath, 'r', encoding='utf-16') as f:
            lines = f.readlines()
            for line in lines[-n:]:
                print(line.strip())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    read_utf16_last_n("cloud_run_logs.txt")
