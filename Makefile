REPOSITORY=hub.docker.com
VERSION=v1.0.0
NAME=jam
PORT=3000
RUN_STATEMENT=docker run --rm -p $(PORT):3000 $(REPOSITORY)/$(NAME):$(VERSION)
	build:
			docker build -t $(REPOSITORY)/$(NAME):$(VERSION) .
run:
			$(RUN_STATEMENT)
publish:
			docker push $(REPOSITORY)/$(NAME):$(VERSION)
export_run:
			echo "$(RUN_STATEMENT)"
