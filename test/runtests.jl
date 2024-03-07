using Test
using TextChunking


@testset "FixedLengthChunking" begin
    txt = "The Julia Programming Language!"
    clf = FixedLengthChunking(4, 1)
    res = clf(txt)

    @test length(res) == 8
    @test res[end] == "age!"

    clf = FixedLengthChunking(4, -1)
    @test_throws AssertionError clf(txt) # "Overlap cannot be negative"
end


@testset "RecursiveCharacterChunking" begin
    txt = "The Julia\n\nProgramming Language!"
    clf = RecursiveCharacterChunking(chunk_length=4)
    res = clf(txt)

end