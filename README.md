# My Bachelor's Degree Final Project

This repository contains all the content related to my Bachelor's Degree Final Project.

## Content
* The 3 subsistems of this project (__Topics and Summary__, __Web backend__ and __Web frontend__) as git submodules (each subsistem is in it's own git repository).
* The Docker files (.dockerignore and Dockerfile) needed to generate a __Docker image that contains the topics_and_summary and the web_backend subsistems__. This Docker image is the one used to deploy the backend to Heroku. This files can't be moved to the web_backend project, because they use the topics_and_summary and the web_backend projects. Another approach would be to include the topics_and_summary project as a git submodule inside the web_backend project, but currently the other approach is used.
* The __documentation of this project__ (in spanish), including: the planning, analysis, design, implementation, tests, conclusions and possible extensions of this project.
* The __presentation of this project__ (in spanish), that summarizes the documentation.
