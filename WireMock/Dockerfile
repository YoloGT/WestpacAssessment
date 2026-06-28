FROM wiremock/wiremock:3.9.1

COPY mappings /home/wiremock/mappings

EXPOSE 8080

CMD ["--global-response-templating", "--verbose"]
