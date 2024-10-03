# README #

### What is this repository for? ###

* Firewall with Shakti C-Class on FPGA

### How do I get set up? ###

* Makefile contains all the rules to compile and execute all modules.
* For Loopback design, use **make Loopback_all** and for normal two ethernet design, use **make all**
* Refer to README in bloomfilter_generator for bloomfilter generation steps
* bloomfilter_generator is currently not meant to create other Firewall modules like FSBV (# TODO #)
* TbEthFabric: Testbench containing two Ethernet IPs. When one receives, it transmits to the other.
* TbEthConnection: Testbench that tests whether Ethernet Master Transactor works or not.

### Some nuisances to be fixed ###
* Makefile needs to be modified so we can use multi-core execution
* bloomfilter code needs some fix for FSBV module

### Contribution guidelines ###

* Approach the owner

### Who do I talk to? ###

* Repo owner or admin
Surya Prasad S, suryaprasad01@gmail.com
A M S Arun Krishna, <Beware before contacting>
Ankit Raj, ankit@pinacalabs.com

* Guided by
Prof. Chester Rebeiro
Email id: chester@cse.iitm.ac.in
