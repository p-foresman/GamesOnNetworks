using Graphs, JSON3

graph = erdos_renyi(10, 2)
matrix = Matrix(adjacency_matrix(graph))
string = "$matrix"


function adjMatrixStringParser(db_matrix_string)
    string = chop(db_matrix_string, head=1, tail=1)
    new_vector = Vector{Int64}([])
    for i in string #parse the string into a vector
        if i != ' ' && i != ';'
            push!(new_vector, parse(Int64, i))
        end
    end
    size = Int64(sqrt(length(new_vector))) #will always be a perfect square due to matrix being adjacency matrix
    new_matrix = reshape(new_vector, (size, size)) #reshape parsed vector into matrix (this result can be fed into the SimpleGraph() function)
    return new_matrix
end

test_matrix = adjMatrixStringParser(string)
#readdlm()


payoff_matrix = Matrix{Tuple{Int8, Int8}}([(0, 0) (0, 0) (70, 30);
                                        (0, 0) (50, 50) (50, 30);
                                        (30, 70) (30, 50) (30, 30)])

other_string = "$payoff_matrix"


function payoffMatrixStringParser(db_matrix_string)
    string = split(chop(db_matrix_string, head=18, tail=1), ['(', ')', ","])
    return string
end

println(payoffMatrixStringParser(other_string))