# docker_rtklib_rnxbslns
A docker repository to process GNSS baselines base on RINEX data obtained from online data centers.  
  
## Features
- Automatically download GNSS data based on RTKLIB Download API
- Process multiple rovers and bases in one command

## Configurable options
- /conf/rovers.lst  File with rovers station to be processed
- /conf/bases.lst  File with base station to be processed
- /conf/downloadpaths.lst  See RTKLIB manual
- /bin/rnx2ppk Set IP of PostgreSql database with -p option in pos2postgresql.pl command

## Docker commands
- Building:  docker build -f .\DockerfileMKL --rm -t geopinie/rnxbslns .\
- Running: docker run -m="128m" --memory-swap="128m" --cpus="1" --restart=always --name rnxbslns -d geopinie/rnxbslns
