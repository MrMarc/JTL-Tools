All feedback is requested/welcome/encouraged.

If there are fixes in the code ... make them there 

As for the docs and what "needs" to be done. Try to keep that here so
that they can be prioritized in one spot.

Feel free to do any of these. It helps us all have a better tool. Just
put your name beside the item so that we won't all try to do the same thing :)

- Place code in github (Marc)

- Address issues related to false positive substitutions
  - i.e. strftime templates

- Greedy vs non-greedy regex substitutions 
  - test with multiple variables on the same line ...

- Use FindBin instead of fileparse in sigRun.pl (others?)

- extract input variables from XML rather than from code

- automatically create ValidateInput routines ...

- finish documentation
  - installation howtos

- tool to create Signiant-ified XML
  - standard XML tools use the standard XML closures i.e. <variables/>
    instead of Signiant's old style <variables></variables>
  - this poses a problem not only in input variables file but also on
    the re-insertion of modified code into a JTL XML file.
  - it shouldn't be too difficult to create a script/routine that
    parses, looks for a regular expression indicating a self-closed tag
    and have it re-write the tag pairs.

- make toolset recognize:
  - component XML
  - component ZIP files
  - application ZIP files
  - Signiant system variables like %dds_default_dir%

- the ability to run multiple components in succession
