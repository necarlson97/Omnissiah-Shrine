import re
import subprocess
import pyphen


def load_syllables(file_path='./syllables.txt'):
    """
    Load syllables from a syllables.txt file into a dictionary for quick lookup
    Format: word=hy-phen-a-ted
    """
    syllables_dict = {}
    conflicts = {}

    with open(file_path, 'r', encoding='utf-8') as file:
        for line in file:
            line = line.strip()
            if '=' in line:
                word, hyphenated = line.split('=', 1)
                lower_word = word.lower()

                # If the word does not match our previous entry, keep track
                # of this conflict
                if syllables_dict.get(lower_word) not in [None, hyphenated]:
                    conflicts.setdefault(lower_word, set()).update(
                        [syllables_dict[lower_word], hyphenated])

                syllables_dict[lower_word] = hyphenated

    return syllables_dict, conflicts

# Load the syllables.txt file once
SYLLABLES_DICT, _ = load_syllables()
def get_hyphenated(word):
    # Normalize the word (lowercase and remove trailing punctuation for lookup)
    word_cleaned = re.sub(r'[.,!?]+$', '', word.lower())

    # Look in our manual dictionary
    if word_cleaned in SYLLABLES_DICT:
        return SYLLABLES_DICT[word_cleaned]

    # Otherwise, rely on pyphen
    dic = pyphen.Pyphen(lang='en')
    hyphenated = dic.inserted(word_cleaned)
    return hyphenated

def say_word(word):
    # To help the human, have espeak try to say it
    command = [
        "espeak",
        f"{word}"
    ]

    try:
        subprocess.run(
            command, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
    except subprocess.CalledProcessError as e:
        print(
            f"Error generating audio for {word}: "
            f"{e.stderr.decode('utf-8')}"
        )
        raise

def resolve_conflicts(file_path='./syllables.txt'):
    """
    Identify and resolve conflicts in the syllables.txt file.
    """
    syllables_dict, conflicts = load_syllables(file_path)

    if not conflicts:
        print("No conflicts found.")
        return

    print("Conflicts detected. Resolving...")

    resolved_entries = {}

    for word, options in conflicts.items():
        # TODO this is bold, but for now, if pyphen agrees, just use that
        dic = pyphen.Pyphen(lang='en')
        hyphenated = dic.inserted(word)
        if hyphenated in options:
            print(f"Trusting pyphen for {hyphenated}")
            resolved_entries[word] = hyphenated
            continue
        else:
            # print(f"Pyphen '{hyphenated}' not in {options}")
            options.add(hyphenated)

        # TODO this is bad, but lets just force a solution with this
        resolved_entries[word] = max(options, key=lambda w: w.count('-'))
        print(f"Choosing {resolved_entries[word]}")

    input("CTRL+C now to quit")
    write_resolved(resolved_entries, file_path)


def user_input(word, options, resolved_entries):
    print(f"Choose the correct breakdown for the word: {word}")
    options = list(options)
    for i, option in enumerate(options, 1):
        print(f"{i}. {option}")
    print(f"{len(options) + 1}. Remove all entries for this word")
    print("q. Quit and come back")
    print("s. Skip for now")
    print("w. Hear the word again")

    while True:
        say_word(word)
        try:
            choice = input("Enter your choice: ")
            try:
                int_choice = int(choice)
            except ValueError:
                int_choice = -1

            if 1 <= int_choice <= len(options):
                resolved_entries[word] = options[int_choice - 1]
                break
            elif int_choice == len(options) + 1:
                resolved_entries[word] = None  # Mark for removal
                break
            elif choice == "q":
                # TODO broken
                return resolved_entries
            elif choice == "s":
                break
            elif choice == "w":
                # hear the word again
                pass
            else:
                print("Invalid choice. Try again.")
        except ValueError:
            print("Invalid input. Please enter a number.")
    return resolved_entries

def write_resolved(resolved_entries, file_path='./syllables.txt'):
    # Write the resolved file
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    with open(file_path, 'w', encoding='utf-8') as file:
        for line in lines:
            line = line.strip()
            if '=' in line:
                word, hyphenated = line.split('=', 1)
                lower_word = word.lower()
                if lower_word in resolved_entries:
                    if resolved_entries[lower_word] == hyphenated:
                        file.write(line + '\n')
                else:
                    file.write(line + '\n')

    print("Conflicts resolved and file updated.")

if __name__ == "__main__":
    try:
        resolve_conflicts()
    except FileNotFoundError:
        print(
            "syllables.txt not found. "
            "Please ensure the file exists in the current directory."
        )
    except Exception as e:
        print(f"An error occurred: {e}")
