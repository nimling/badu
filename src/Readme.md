
# Rules

You need to try to aviod CRAP: Code that's Complex, Redundant, and Antipattern-Prone:
    - Every cmdlet in this codebase is here to serve one function: to deploy bicep files in a timely and easy to maintain fashion.
    - Everything else is superflous. This might change in the future, however if there is a need to handle writing, importing and maintaining bicep.
    - if you need to do some complexity, please split it up and explain the thought process
    - If you see CRAP code, please try to fix it.

Every cmdlet is written in 1 file, dont share files. the name of the file should be `Cmdlet-Name.ps1`, and pester files should be `Cmdlet-Name.Tests.ps1`
Classes can be written together as they often are shared. The name of the files should be `Name.class.ps1`
every cmdlet-file needs 1 pester test file. The Different stages you need to think about is:
 - General
    - Used to validate basic functionality of the cmdlet, Like parameteres, output types and such.
    - Most of it is described in main.Tests.ps1, but you can add your own specialied "General" tests if you want.
    - current tests are:
        - every command in every cmdlet should exists within the current runspace (after i have loaded all files from ./src)
            - This is good to handle cases where a command hve changed name
        - every command should have test in same folder
        - if you have more general tests, please add them
 - Unit tests
    - Used to test the core functionality of a cmdlet. please make good use of testcases for your functionality, but remember that someone else is going to read your code later on, so dont make "CRAP" code.
 - Integration tests


# Pester
as i said, every cmdlet needs a test, but there is also a "General" 