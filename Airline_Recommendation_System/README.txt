DESCRIPTION
The goal of the project is to give users personalized suggestions for airlines. 
The airline recommendation system has two main functions: users can get airline suggestions based on their preferences; the system collects user reviews to keep build up the database.
The package has three components: README.txt, CODE, DOC. 
Below is the structure of the three parts:

README.txt - a quick user guide of the system

CODE - all codes needed to run the system
##main files: 
  front page: home.html
  back-end service file: server_main.py
##main folders:
  DB: the database files
  templates: front-end html files
  static: resources needed. 
      css: css files
      libs: JavaScript files
      json: json data files
      png: png and gif images
  model: for the python files of the recommendation model, as well as python functions that call database queries to support server_main.py
##home page:
 * Running on http://127.0.0.1:5000
 * Running on http://localhost:5000
We've also added a YouTube link at the end of this README.txt file to quickly guide you through installing and using the system.

DOC - includes team045report.pdf and team045poster.pdf

INSTALLATION
1. Install python, scikit-learn, pandas, and flask.
2. Download the zip file and unzip it to your local computer.
3. Run the backend service. For Windows user, open Command Prompt (For Mac user, Open Mac terminal), run "cd <your absolute path of the CODE folder>" and then Run "python server_main.py", or run "python.exe <your absolute path of the CODE folder>\server_main.py" directly.

EXECUTION 
1. Open http://127.0.0.1:5000/ or http://localhost:5000 at your browser.
2. Go to the top left and click 'Recommendation'. Make selections from the menu on the left side of the control panel, then click 'Submit'.
3. To see more information about each recommended airline, click on the 'Details' link. You'll find all the details in the panel below the map section.
4. Go to the lower right and click the 'here' link, it will lead you to the airline's booking website.
5. Go to the top left and click 'Review'. Give your ratings and review for the airline, then click 'Submit'.

DEMO VIDEO
https://www.youtube.com/watch?v=KUAGP8V4Ulw