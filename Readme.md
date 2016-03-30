#Developing Signiant Components

Signiant workflow components are the glue that makes Signiant workflows useful
in our customer's environments. Making the components easier to create, test
and debug is critical to making workflows more accessible.

##How customers run/debug/test components presently.

The Signiant workflow canvas allows workflow developers to layout the
components in their job template. The code that makes up each
component is modified directly on the canvas in a dialog that
incorporates a basic editor.

The embedded text editor is reasonable for simple editing tasks. It even has
Perl syntax highlighting (provided the file/component has less than 1000 lines of
code). For people used to a more sophisticated development environment or
IDEs, it leaves much to be desired.

###Running

A typical technique for writing Signiant components is to create a
workflow with a single component connected to a start component. This
simple "one-component" workflow model allows testing of code changes
while minimizing waiting time.

[[Show diagram of one component workflow]]

Developers map the component inputs to the start component and a create
a job run the component. Give, this job a schedule of "never"
and run it manually. Thus preventing the job from launching inadvertently.
It is also best to set the logging level to Debug to ensure that the
maximum amount of useful information is in the logs.

To run the component, run the job manually as you would any other
Signiant job. The details page will update with the information related
to your component. Any logging information can be obtained from the job
log.

###Debugging

Debugging the component is an iterative (read: painful) process of
verifying output from the job log and making the corresponding changes
to the code. Signiant does not include a debugger so developers unable
to change values in their code mid-job to verify behaviour.

To change input parameters edit the job's input values and re-run the
job.

###Automated testing

While it is possible, a far from optimal technique for automated testing of
workflows is to use Selenium. How to do this is beyond
the scope of this document. The process for fully automated testing is
essentially:

- (if necessary) import the job template library using a SOAP API
- create & run the job, using the SOAP API
- when the job finishes, use Selenium's text parsing to look for expected
  values in the job log.

##Can We Do it Better?

Signiant's in-house developers make use of a "trick" to reference files
in the Agent's file system to use their editor of choice to perform their
code editing tasks.

[[Show diagram of file:/// technique]]

Using this method has the benefit of allowing the developer to develop/modify
code in an environment familiar to them. The code for the component
is "taken" (i.e. opened and pre-parsed) by the manager at workflow run time.
Round-tripping code changes using the job based interface is slow and
limited. To speed-up workflow creation and reduce ramp-up time an
easier mechanism for writing and debugging Signiant Perl component
commands is necessary.

###Alternatives

####Integrate better IDE with JTL canvas

The obvious first suggestion that people discuss to address these issues
is to augment the code editing to make it more of a full-fledged IDE
that includes debugging.

This poses a few problems:

- Which IDE?

Developers are notorious for having their favourite IDE that they are
comfortable with. Making them learn a new one is unlikely to accelerate
any component development.

- Adding more JavaScript to the manager UI

Too much effort ...

- Debugger

Integrating I/O from the manager UI to a text based debugger *(dds_perl
-d)* is difficult problem. While not impossible it is a great deal of effort.

####Provide a mechanism for getting component code into a better IDE

The alternative is to provide a mechanism to get the code into the
developer's own workflow. Allowing them to create, modify, debug, and
run in an environment that already works for them.

To do this, the mechanism would need to allow developers to

- download job template libraries from their manager
- extract components from the job template library
- run/debug code after:
    - inserting SolutionScripts
    - Perform variable substitutions
- re-insert code into job template libraries
- upload modified job template libraries to their manager

##Component Coding Tool set

The Component Coding Tool set is a set of scripts that will allow a
developer to round-trip a workflow so that they can extract, modify,
run/debug and return their code to/from their Signiant manager.

In the spirit of Unix, it provides a series of scripts that perform each
of the listed functions independent of the others. In this way
developers aren't limited to interacting in one set way or for one set
purpose. For example, a developer can start with an already exported job
template library and never connect with a Signiant manager.

These tools are provided in Perl. We encourage you to use them and
modify them to meet their needs. We ask that you consider
re-contributing any modifications so that others may benefit from
changes that you make.

###Retrieving the Job Template Library from a Signiant Manager

The *getJTL.pl* script provides a mechanism to contact a Signiant
manager and download a copy of a named job template library. This
script requires the ability to contact the manager to make a SOAP
connection.

    getJTL.pl -j MyJobTemplate -m manager01 -u admin -p password

This command will connect to the Signiant manager at *manager01* as the
user *admin* with the password *password* and download the
*MyJobTemplate* job template library. The job template library will be
stored as MyJobTemplate.xml.

NOTE: This connection and download can be slow.

###Extracting the Component Code from a Job Template Library XML

If you've ever looked inside the XML that makes up the Job Template
Library XML you'll notice the component code along with a great deal of
other information. The other information encodes various
things including variable mappings, and position on the editing canvas.

Editing the XML directly is neither feasible nor recommended. The
Component Coding Tool set provides a script that will allow you to
extract any/all component code from a single or all of the components
that are within a Job Template Library XML file.

    extractpl.pl -j MyJobTemplateLibrary 

This command will extract each command from every component within the
Job Template Library into a directory structure with the following format:

    ./<JTLNAME>/<STARTCOMPONENTNAME>/<COMPONENTNAME/COMMANDNAME.pl 
    ./<JTLNAME>/<STARTCOMPONENTNAME>/<COMPONENTNAME/COMMANDNAME.in 

The .pl file will contain the source code for the given command while
the .in file is an XML file that lists the inputs that the given command
code requires as input.

In many cases, running the command above would be overkill and will
extract **everything**. To extract all the command code for a given
component, use the *-comp* option to specify the specific component and
the *-cmd* option to specify the specific command.

    extractpl.pl -j MyJobTemplateLibrary -comp My_Specific_Component -cmd tgt_proc_cmd

This command will extract the *tgt_proc_cmd* from
*My_Specific_Component* and nothing else. It will also create the input
file for the specified component.

The *extractpl.pl* script has a variety of other options that perform
various useful functions. For more information, refer to the manual page
here:

    extractpl.pl -?

The code for the commands can be edited with the editor or IDE of the
developer's choice.

###Run/Debug

Having the ability to modify the code is only half-way useful. The
ability to run and debug the code as well makes the development cycle
significantly better.

**Background:** Signiant command components, when run by a manager undergo
a pre-processing and variable substitution phase at run-time. This is
similar to how pre-processing works in C/C++.

#Road map
All feedback is requested/welcome/encouraged.

Feel free to fork and make pull requests...

As for the docs and what "needs" to be done. Try to keep that here so
that they can be prioritized in one spot.

Feel free to do any of these. It helps us all have a better tool. Just
put your name beside the item so that we won't all try to do the same thing :)

##Tasks/To-dos:

- Address issues related to false positive substitutions
  - i.e. strftime templates

- Greedy vs non-greedy regex substitutions 
  - test with multiple variables on the same line ...

- Use FindBin instead of fileparse in sigRun.pl (others?)

- extract input variables from XML rather than from code

- automatically create ValidateInput routines ...

- finish documentation
  - installation howtos

- create Signiant-ified XML
  - standard XML tools use the standard XML closures i.e. <variables/>
    instead of Signiant's old style <variables></variables>
  - this poses a problem not only in input variables file but also on
    the re-insertion of modified code into a JTL XML file.
  - it shouldn't be too difficult to create a script/routine that
    parses, looks for a regular expression indicating a self-closed tag
    and have it re-write the tag pairs.

- make tool set recognize:
  - component XML
  - component ZIP files
  - application ZIP files
  - Signiant system variables like %dds_default_dir%

- the ability to run multiple components in succession
