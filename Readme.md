##### [Project 3](http://cwcserv.ucsd.edu/~billlin/classes/ECE111/project3.php)

Project 3 is an implementation of the SHA256 algorithm.  
  
See [Lecture 6](http://cwcserv.ucsd.edu/~billlin/classes/ECE111/lectures/Lecture6.pptx) slides for a description of the SHA256 algorithm and a description of Project 3.  
  
See the Wikipedia page on [SHA-2](https://en.wikipedia.org/wiki/SHA-2) for additional information.  
  
For Project 3:

- Your design must pass the testbench provided: [tb_simplified_sha256.sv](http://cwcserv.ucsd.edu/~billlin/classes/ECE111/examples/tb_simplified_sha256.sv).
- **Use the cycle count** from the [tb_simplified_sha256.sv](http://cwcserv.ucsd.edu/~billlin/classes/ECE111/examples/tb_simplified_sha256.sv) testbench for your delay calculations.
**Submission instructions**: Turn in all of these files into one compressed file, named like (student1 name)_(student2 name)_project3.zip, or (student name)_project3.zip if you are working alone. The student name should be of the form "(LastName, FirstName)". Please use parentheses. e.g., (Smith, Bob)_(Jones, Alice)_project3.zip.

1. Provide a summary of your results using the following spreadsheet:
    - [summary.xlsx](http://cwcserv.ucsd.edu/~billlin/classes/ECE111/summary.xlsx)

2. Copy of your SystemVerilog HDL source code for your SHA256 design.
3. Copy of the ModelSim simulation results. Please check the [FAQs](http://cwcserv.ucsd.edu/~billlin/classes/ECE111/faq.php) page on how to save your ModelSim transcripts. You just need to submit the ModelSim transcripts, not the waveforms.
4. Copy of the "fit" report (RPT file) with area numbers and "sta" report (RPT file) with Fmax summary generated using Quartus. These files are generated in the project directory. You can also send in screenshots from the GUI for area and Fmax instead of the files.
5. Use the **Fmax** result from the **Slow 900mV 100C Model** to report your clock period. (Do not use the Restricted Fmax.) Please make sure that you select the **EP2AGX45DF29I5**device from the **Arria II GX** FPGA family when running Quartus.
6. Depending if you are enrolled in Section A00 or B00, you should send your compressed file to one following respective email addresses:  
  
ece111a00@gmail.com   
ece111b00@gmail.com  
  
If you and your partner are in different sections, then email your compressed file to the email address that corresponds to the section of the student who is submitting.  
  
The "Subject" line of your email should say "Simplified SHA256 project".
This project **will be graded for P/NP**.

