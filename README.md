python-ELM
==========

A python emulator for the ELM327 OBD-II adapter. Built for testing [python-OBD](https://github.com/brendanwhitfield/python-OBD).

This emulator can process examples in [*python-OBD* documentation](https://python-obd.readthedocs.io/en/latest/) and reproduces the message flow
generated by a Toyota Auris Hybrid car, including custom messages.

# Installation

```shell
# Checking python version (should be 3.7 or higher)
python3.7 -V

# Installing prerequisites
python3.7 -m pip install pyyaml
python3.7 -m pip install hexdump

# Downloading python-ELM
git clone https://github.com/ircama/python-ELM.git
cd python-ELM
```

# Usage

Run with:

```shell
python3.7 -m elm
```

# Compatibility

Tested with Python 3.6 and 3.7. Python 2 is not supported.

This code needs pseudo-terminal handling (pty support, `import pty`) which is platform dependent and runs with UNIX OSs. With Windows, [cygwin](http://www.cygwin.com/) is supported.


# Description

The serial port to be used by the application interfacing the emulator is displayed when starting the program. E.g.,:

    Running on /dev/pts/1

A [dictionary](https://docs.python.org/3.7/tutorial/datastructures.html#dictionaries) is used to define commands and PIDs. The dictionary includes more sections (named scenarios):

- `'AT'`: supported AT commands
- `'default'`: supported default PIDs
- `'test'`: different values for some of the default PIDs
- any additional custom section can be used to define specific scenarios

Default settings include both the 'AT' and the 'default' scenarios.

The dictionary used to parse each ELM command is dynamically built as a union of three defined scenarios in the following order: 'default', 'AT', custom scenario (when applied). Each subsequent scenario redefines commands of the previous scenarios. In principle, 'AT scenario is added to 'default' and, if a custom scenario is used, this is also added on top, and all equal keys are replaced. Then the Priority key defines the precedence to match elements.

If `emulator.scenario` is set to a string different from *default*, the custom scenario set by the string is applied; any key defined in the custom scenario replaces the default settings ('AT' and 'default' scenarios).

The key used in the dictionary consists of a unique identifier for each PID. Allowed values for each key (PID):

- `'Request'`: received data; a [regular expression](https://docs.python.org/3/library/re.html) can be used
- `'Descr'`: string describing the PID
- `'Exec'`: command to be executed
- `'Log'`: *logging.debug* argument
- `'ResponseFooter'`: run a function and returns a footer to the response (a [lambda function](https://docs.python.org/3/reference/expressions.html#lambda) can be used)
- `'ResponseHeader'`: run a function and returns a header to the response (a [lambda function](https://docs.python.org/3/reference/expressions.html#lambda) can be used)
- `'Response'`: returned data; can be a string or a list/tuple of strings; if more strings are included, the emulator randomly select one of them each time
- `'Action'`: can be set to 'skip' in order to skip the processing of the PID
- `'Header'`: if set, process the command only if the corresponding header matches
- `'Priority'=number`: when set, the key has higher priority than the default (highest number = 1, lowest = 10 = default)

The emulator provides a monitoring front-end, supporting commands. The monitoring front-end controls the backend thread executing the actual process.

At the prompt `CMD> `, the emulator accepts the following commands:

- `help` = List available commands (or detailed help with "help cmd").
- `quit` (or end-of-file/Control-D, or break/Control-C) = quit the program
- `counters` = print the number of each executed PID (upper case names), the values associated to some 'AT' PIDs (*cmd_...*), the unknown requests, the emulator response delay, the total number of executed commands (*commands*) and the current scenario (*scenario*)
- `pause` = pause the execution.
- `prompt` = toggle prompt off/on
- `resume` = resume the execution after pausing; prints the used device.
- `delay <n>` = delay each emulator response of `<n>` seconds (floating point number; default is 0.5 seconds)
- `wait <n>` = delay the execution of the next command of `<n>` seconds (floating point number; default is 10 seconds)
- `off` = switch to 'engineoff' scenario
- `scenario <scenario>` = switch to `<scenario>` scenario; if the scenario is missing or invalid, defaults to `'test'`
- `default` = reset to 'default' scenario
- `reset` = reset the emulator (counters and variables)
- any other Python command can be used to query/configure the backend thread

At the command prompt, cursors and [keyboard shortcuts](https://ss64.com/bash/syntax-keyboard.html) are allowed. Autocompletion is active for all previously described commands and also allows Python keywords, built-ins and globals.

The command prompt also allows configuring the `emulator.answer` dictionary, which has the goal to redefine answers for specific PIDs (`'Pid': '...'`). Its syntax is:

```
emulator.answer = { 'pid' : 'answer', 'pid' : 'answer', ... }
```

Example:

```
emulator.answer = { 'SPEED': 'NO DATA\r', 'RPM': 'NO DATA\r' }
```

The above example forces SPEED and RPM PIDs to always return "NO DATA".

To reset the *emulator.answer* string to its default value:

```
emulator.answer = {}
```

The dictionary can be used to build a workflow.

The front-end can also be controlled by an external piped automator.

Logging is controlled through `elm.yaml` file (in the current directory by default). Its path can be set through the *ELM_LOG_CFG* environment variable.

The logging level can be dynamically changed by referencing `emulator.logger`. For instance, if the logging configuration has *stdout* as the first handler (default settings of the provided `elm.yaml` file), the following commands will change the logging level:

```
emulator.logger.handlers[0].setLevel(logging.DEBUG)
emulator.logger.handlers[0].setLevel(logging.INFO)
emulator.logger.handlers[0].setLevel(logging.WARNING)
emulator.logger.handlers[0].setLevel(logging.ERROR)
emulator.logger.handlers[0].setLevel(logging.CRITICAL)
```

## ObdMessage Dictionary Generator for "python-ELM" (obd_dictionary) ##

*obd_dictionary* is a dictionary generator for "python-ELM".

It queries the vehicle via python-OBD for all available command and is also able to process custom PIDs described in [Torque CSV files](https://torque-bhp.com/wiki/PIDs).

Its output is a python *ObdMessage* dictionary that can be added to the *elm.py* program of *python-ELM*, so that the emulator will be able to provide the same commands returned by the car.

Notice that querying the vehicle might be invasive and some commands can change the car configuration (enabling or disabling belts alarm, enabling or disabling reverse beeps, clearing diagnostic codes, controlling fans, etc.). In order to prevent dangerous PIDs to be used for building the dictionary, a PID blacklist can be edited in elm.py.

```
usage: obd_dictionary.py [-h] -i DEVICE [-c [CSV_FILE]] [-o [FILE]] [-v] [-V]
                         [-p PROBES] [-d DELAY] [-D DELAY_COMMANDS]
                         [-n CAR_NAME] [-b] [-m]

optional arguments:
  -h, --help            show this help message and exit
  -i DEVICE             serial port connected to the ELM327 adapter (required
                        argument)
  -c [CSV_FILE], --csv [CSV_FILE]
                        input csv file including custom PIDs (Torque CSV
                        Format: https://torque-bhp.com/wiki/PIDs) '-' reads
                        data from the standard input
  -o [FILE], --out [FILE]
                        output dictionary file generated after processing
                        input data (replaced if existing). Default is to print
                        data to the standard output
  -v, --verbosity       print process information
  -V, --verbosity_debug
                        print debug information
  -p PROBES, --probes PROBES
                        number of probes (each probe includes querying all
                        PIDs to the OBDII adapter)
  -d DELAY, --delay DELAY
                        delay (in seconds) between probes
  -D DELAY_COMMANDS, --delay_commands DELAY_COMMANDS
                        delay (in seconds) between each PID query within all
                        probes
  -n CAR_NAME, --name CAR_NAME
                        name of the car (dictionary label; default is "car")
  -b, --blacklist       include blacklisted PIDs within probes
  -m, --missing         add in-line comment to dictionary for PIDs with
                        missing response
```

Sample usage: `obd_dictionary.py -i /dev/ttyUSB0 -c car.csv -o ObdMessage.py -v -p 10 -d 1 -n mycar`
