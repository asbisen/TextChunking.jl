
"""
    FixedLengthChunking(; chunk_length, overlap)

Create a FixedLengthChunking object with the given chunk length and overlap.
"""
@kwdef struct FixedLengthChunking
    chunk_length::Int = 1024
    overlap::Int = 0

    function FixedLengthChunking(chunk_length, overlap)
        (overlap > chunk_length)  && throw(ArgumentError("Overlap cannot be greater than chunk length"))
        (overlap < 0)             && throw(ArgumentError("Overlap cannot be negative"))
        (chunk_length <= 0)       && throw(ArgumentError("Chunk length must be positive"))
        new(chunk_length::Int, overlap::Int)
    end
end

function (f::FixedLengthChunking)(text::String)
    text_length = length(text)
    chunks = []

    idx = 1
    while true
        ovrlp = (idx - f.overlap) > 0 ? f.overlap : 0
        st = idx - ovrlp

        if idx + f.chunk_length - 1 > text_length
            push!(chunks, text[st:end])
            break
        else
            push!(chunks, text[st:st+f.chunk_length-1])
            idx = idx + f.chunk_length
        end
    end
    return chunks
end


"""
    RecursiveCharacterChunking(; chunk_length, delimiters)

Recursively split the data using the provided `delimiters` (default: ["\\n\\n", "\\n", "  ", " "]) 
in ordered manner and `chunk_length` (default: 4096). The function will split the data using the
first delimiter and then recursively split the chunks using the next delimiter if the chunk
size is larger than the provided `chunk_length`. If all `delimiters` are exhausted then the function
will split the data based on the `chunk_length`. The function will merge consecutive chunks if they 
are smaller than `chunk_length`.

# Arguments

- delimiters::Array{String}: The delimiters to be used for splitting the data
- chunk_length::Int: The size of the chunk

"""
@kwdef struct RecursiveCharacterChunking
    chunk_length::Int = 1024
    delimiters::Vector{Union{String, Regex}} = ["\n\n", "\n", "  ", ".", ""]
end

function (f::RecursiveCharacterChunking)(text::Vector{T}) where {T <: Any}
    len = length(text)
    res = Array{Any}(undef, len)
    for i in 1:len
        res[i] = f(text[i])
    end
    res 
    #println("Type: $(typeof(text)), Length: $(length(text))")
    #f.(text)
end

function (f::RecursiveCharacterChunking)(text::T) where {T <: AbstractString}
    chunks = []

    @assert f.chunk_length > 0 "Chunk length must be positive"

    tkns = split( text, f.delimiters[1], keepempty=false )
    idx = 1

    while idx <= length(tkns)
        c = tkns[idx]
        if length(c) <= f.chunk_length
            push!(chunks, c)
            idx += 1

        elseif length(c) > f.chunk_length && length(f.delimiters[2:end]) > 0
            nf = RecursiveCharacterChunking(chunk_length=f.chunk_length, delimiters=f.delimiters[2:end])
            r = nf(c)
            chunks = cat(chunks, r, dims=1)
            idx += 1

        elseif length(c) > f.chunk_length && length(f.delimiters[2:end]) == 0
            r = [c[i:min(i+f.chunk_length-1,end)] for i in 1:f.chunk_length:length(c)]
            chunks = cat(chunks, r, dims=1)
            idx += 1
        end
    end

    # merge consecutive chunks if they are too small
    merged_chunks = []
    for (idx, c) in enumerate(chunks)
        # no prev_chunk to merge with first chunk
        prev_chunk_len = (length(merged_chunks) == 0) ? f.chunk_length + 1 : length(merged_chunks[end])

        if length(c) + prev_chunk_len  <= f.chunk_length    # merge if the chunks are smaller than chunk_length
            merged_chunks[end] = join([merged_chunks[end], c], " ")
        else
            push!(merged_chunks, c)
        end
    end

    merged_chunks
end


