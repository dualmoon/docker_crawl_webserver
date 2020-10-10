# crawl-webserver

Use docker run -d -p 8080:8080 --name some-crawl -v ${PWD}/saves:/crawl/crawl-ref/source/saves crawl-webserver

You can also mount /crawl/crawl-ref/sources/rcs to have persistent RCs, or even /crawl to a local copy of the crawl repo so you can easily pull/rebuild 

Open URL http://127.0.0.1:8080
