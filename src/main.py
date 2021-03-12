import numpy


def handle_request(request):
    number = request.path[1:]
    try:
        return str(numpy.pi * numpy.double(number))
    except ValueError:
        return "Invalid number: " + number