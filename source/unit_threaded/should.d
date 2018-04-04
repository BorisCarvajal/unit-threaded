/**
 * This module implements custom assertions via $(D shouldXXX) functions
 * that throw exceptions containing information about why the assertion
 * failed.
 */

module unit_threaded.should;

import std.traits; // too many to list
import std.range; // also


/**
 * An exception to signal that a test case has failed.
 */
class UnitTestException : Exception
{
    this(in string msg, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        this([msg], file, line, next);
    }

    this(in string[] msgLines, string file = __FILE__,
         size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        import std.string: join;
        super(msgLines.join("\n"), next, file, line);
        this.msgLines = msgLines;
    }

    override string toString() @safe const pure
    {
        import std.algorithm: map;
        return () @trusted { return msgLines.map!(a => getOutputPrefix(file, line) ~ a).join("\n"); }();
    }

private:

    const string[] msgLines;

    string getOutputPrefix(in string file, in size_t line) @safe const pure
    {
        import std.conv: to;
        return "    " ~ file ~ ":" ~ line.to!string ~ " - ";
    }
}

/**
 * Verify that the condition is `true`.
 * Throws: UnitTestException on failure.
 */
void shouldBeTrue(E)(lazy E condition, in string file = __FILE__, in size_t line = __LINE__)
{
    shouldEqual(cast(bool)condition, true, file, line);
}

///
@safe pure unittest
{
    shouldBeTrue(true);
}


/**
 * Verify that the condition is `false`.
 * Throws: UnitTestException on failure.
 */
void shouldBeFalse(E)(lazy E condition, in string file = __FILE__, in size_t line = __LINE__)
{
    shouldEqual(cast(bool)condition, false, file, line);
}

///
@safe pure unittest
{
    shouldBeFalse(false);
}


/**
 * Verify that two values are the same.
 * Floating point values are compared using $(D std.math.approxEqual).
 * Throws: UnitTestException on failure
 */
void shouldEqual(V, E)(auto ref V value, auto ref E expected, in string file = __FILE__, in size_t line = __LINE__)
{
    if (!isEqual(value, expected))
    {
        const msg = formatValue("Expected: ", expected) ~
                    formatValue("     Got: ", value);
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe pure unittest {
    shouldEqual(true, true);
    shouldEqual(false, false);
    shouldEqual(1, 1) ;
    shouldEqual("foo", "foo") ;
    shouldEqual([2, 3], [2, 3]) ;

    shouldEqual(iota(3), [0, 1, 2]);
    shouldEqual([[0, 1], [0, 1, 2]], [[0, 1], [0, 1, 2]]);
    shouldEqual([[0, 1], [0, 1, 2]], [iota(2), iota(3)]);
    shouldEqual([iota(2), iota(3)], [[0, 1], [0, 1, 2]]);

}


/**
 * Verify that two values are not the same.
 * Throws: UnitTestException on failure
 */
void shouldNotEqual(V, E)(V value, E expected, in string file = __FILE__, in size_t line = __LINE__)
{
    if (isEqual(value, expected))
    {
        const msg = ["Value:",
                     formatValue("", value).join(""),
                     "is not expected to be equal to:",
                     formatValue("", expected).join("")
            ];
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe pure unittest
{
    shouldNotEqual(true, false);
    shouldNotEqual(1, 2);
    shouldNotEqual("f", "b");
    shouldNotEqual([2, 3], [2, 3, 4]);
}

///
@safe unittest {
    shouldNotEqual(1.0, 2.0);
}



/**
 * Verify that the value is null.
 * Throws: UnitTestException on failure
 */
void shouldBeNull(T)(in auto ref T value, in string file = __FILE__, in size_t line = __LINE__)
{
    if (value !is null)
        fail("Value is not null", file, line);
}

///
@safe pure unittest
{
    shouldBeNull(null);
}


/**
 * Verify that the value is not null.
 * Throws: UnitTestException on failure
 */
void shouldNotBeNull(T)(in auto ref T value, in string file = __FILE__, in size_t line = __LINE__)
{
    if (value is null)
        fail("Value is null", file, line);
}

///
@safe pure unittest
{
    class Foo
    {
        this(int i) { this.i = i; }
        override string toString() const
        {
            import std.conv: to;
            return i.to!string;
        }
        int i;
    }

    shouldNotBeNull(new Foo(4));
}

enum isLikeAssociativeArray(T, K) = is(typeof({
    if(K.init in T) { }
    if(K.init !in T) { }
}));

static assert(isLikeAssociativeArray!(string[string], string));
static assert(!isLikeAssociativeArray!(string[string], int));


/**
 * Verify that the value is in the container.
 * Throws: UnitTestException on failure
*/
void shouldBeIn(T, U)(in auto ref T value, in auto ref U container, in string file = __FILE__, in size_t line = __LINE__)
    if (isLikeAssociativeArray!(U, T))
{
    import std.conv: to;

    if (value !in container)
    {
        fail("Value " ~ to!string(value) ~ " not in " ~ to!string(container), file,
            line);
    }
}

///
@safe pure unittest {
    5.shouldBeIn([5: "foo"]);

    struct AA {
        int onlyKey;
        bool opBinaryRight(string op)(in int key) const {
            return key == onlyKey;
        }
    }

    5.shouldBeIn(AA(5));
}

/**
 * Verify that the value is in the container.
 * Throws: UnitTestException on failure
 */
void shouldBeIn(T, U)(in auto ref T value, U container, in string file = __FILE__, in size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T) && isInputRange!U)
{
    import std.algorithm: find;
    import std.conv: to;

    if (find(container, value).empty)
    {
        fail("Value " ~ to!string(value) ~ " not in " ~ to!string(container), file,
            line);
    }
}

///
@safe pure unittest
{
    shouldBeIn(4, [1, 2, 4]);
    shouldBeIn("foo", ["foo" : 1]);
}


/**
 * Verify that the value is not in the container.
 * Throws: UnitTestException on failure
 */
void shouldNotBeIn(T, U)(in auto ref T value, in auto ref U container,
                         in string file = __FILE__, in size_t line = __LINE__)
    if (isLikeAssociativeArray!(U, T))
{
    import std.conv: to;

    if (value in container)
    {
        fail("Value " ~ to!string(value) ~ " is in " ~ to!string(container), file,
            line);
    }
}

///
@safe pure unittest {
    5.shouldNotBeIn([4: "foo"]);

    struct AA {
        int onlyKey;
        bool opBinaryRight(string op)(in int key) const {
            return key == onlyKey;
        }
    }

    5.shouldNotBeIn(AA(4));
}


/**
 * Verify that the value is not in the container.
 * Throws: UnitTestException on failure
 */
void shouldNotBeIn(T, U)(in auto ref T value, U container,
                         in string file = __FILE__, in size_t line = __LINE__)
    if (!isLikeAssociativeArray!(U, T) && isInputRange!U)
{
    import std.algorithm: find;
    import std.conv: to;

    if (!find(container, value).empty)
    {
        fail("Value " ~ to!string(value) ~ " is in " ~ to!string(container), file,
            line);
    }
}

///
@safe unittest
{
    auto arrayRangeWithoutLength(T)(T[] array)
    {
        struct ArrayRangeWithoutLength(T)
        {
        private:
            T[] array;
        public:
            T front() const @property
            {
                return array[0];
            }

            void popFront()
            {
                array = array[1 .. $];
            }

            bool empty() const @property
            {
                return array.empty;
            }
        }
        return ArrayRangeWithoutLength!T(array);
    }

    shouldNotBeIn(3.5, [1.1, 2.2, 4.4]);
    shouldNotBeIn(1.0, [2.0 : 1, 3.0 : 2]);
    shouldNotBeIn(1, arrayRangeWithoutLength([2, 3, 4]));
}

/**
 * Verify that expr throws the templated Exception class.
 * This succeeds if the expression throws a child class of
 * the template parameter.
 * Returns: The caught throwable.
 * Throws: UnitTestException on failure (when expr does not
 * throw the expected exception)
 */
auto shouldThrow(T : Throwable = Exception, E)
                (lazy E expr, in string file = __FILE__, in size_t line = __LINE__)
{
    import std.conv: text;

    return () @trusted { // @trusted because of catching Throwable
        try {
           const result = threw!T(expr);
           if (result) return result.throwable;
        } catch(Throwable t)
            fail(text("Expression threw ", typeid(t), " instead of the expected ", T.stringof, ":\n", t.msg), file, line);

        fail("Expression did not throw", file, line);
        assert(0);
    }();
}

///
@safe pure unittest {
    void funcThrows(string msg) { throw new Exception(msg); }
    try {
        auto exception = funcThrows("foo bar").shouldThrow;
        assert(exception.msg == "foo bar");
    } catch(Exception e) {
        assert(false, "should not have thrown anything and threw: " ~ e.msg);
    }
}

///
@safe pure unittest {
    void func() {}
    try {
        func.shouldThrow;
        assert(false, "Should never get here");
    } catch(Exception e)
        assert(e.msg == "Expression did not throw");
}

///
@safe pure unittest {
    void funcAsserts() { assert(false, "Oh noes"); }
    try {
        funcAsserts.shouldThrow;
        assert(false, "Should never get here");
    } catch(Exception e)
        assert(e.msg ==
               "Expression threw core.exception.AssertError instead of the expected Exception:\nOh noes");
}


/**
 * Verify that expr throws the templated Exception class.
 * This only succeeds if the expression throws an exception of
 * the exact type of the template parameter.
 * Returns: The caught throwable.
 * Throws: UnitTestException on failure (when expr does not
 * throw the expected exception)
 */
auto shouldThrowExactly(T : Throwable = Exception, E)(lazy E expr,
    in string file = __FILE__, in size_t line = __LINE__)
{
    import std.conv: text;

    const threw = threw!T(expr);
    if (!threw)
        fail("Expression did not throw", file, line);

    //Object.opEquals is @system and impure
    const sameType = () @trusted { return threw.typeInfo == typeid(T); }();
    if (!sameType)
        fail(text("Expression threw wrong type ", threw.typeInfo,
            "instead of expected type ", typeid(T)), file, line);

    return threw.throwable;
}

/**
 * Verify that expr does not throw the templated Exception class.
 * Throws: UnitTestException on failure
 */
void shouldNotThrow(T: Throwable = Exception, E)(lazy E expr,
    in string file = __FILE__, in size_t line = __LINE__)
{
    if (threw!T(expr))
        fail("Expression threw", file, line);
}


/**
 * Verify that an exception is thrown with the right message
 */
void shouldThrowWithMessage(T : Throwable = Exception, E)(lazy E expr,
                                                          string msg,
                                                          string file = __FILE__,
                                                          size_t line = __LINE__) {
    auto threw = threw!T(expr);
    if (!threw)
        fail("Expression did not throw", file, line);

    threw.throwable.msg.shouldEqual(msg, file, line);
}

///
@safe pure unittest {
    void funcThrows(string msg) { throw new Exception(msg); }
    funcThrows("foo bar").shouldThrowWithMessage!Exception("foo bar");
    funcThrows("foo bar").shouldThrowWithMessage("foo bar");
}


//@trusted because the user might want to catch a throwable
//that's not derived from Exception, such as RangeError
private auto threw(T : Throwable, E)(lazy E expr) @trusted
{

    static struct ThrowResult
    {
        bool threw;
        TypeInfo typeInfo;
        immutable(T) throwable;

        T opCast(T)() @safe @nogc const pure if (is(T == bool))
        {
            return threw;
        }
    }

    import std.stdio;
    try
    {
        expr();
    }
    catch (T e)
    {
        return ThrowResult(true, typeid(e), cast(immutable)e);
    }

    return ThrowResult(false);
}



void fail(in string output, in string file, in size_t line) @safe pure
{
    throw new UnitTestException([output], file, line);
}


private string[] formatValue(T)(in string prefix, auto ref T value) {

    import std.conv: to;

    static if(isSomeString!T) {
        // isSomeString is true for wstring and dstring,
        // so call .to!string anyway
        return [ prefix ~ `"` ~ value.to!string ~ `"`];
    } else static if(isInputRange!T) {
        return formatRange(prefix, value);
    } else {
        return [prefix ~ convertToString(value)];
    }
}

// helper function for non-copyable types
string convertToString(T)(in auto ref T value) { // std.conv.to sometimes is @system
    import std.conv: to;
    import std.traits: Unqual;

    static if(__traits(compiles, value.to!string))
        return () @trusted { return value.to!string; }();
    else static if(__traits(compiles, value.toString)) {
        static if(isObject!T)
            return () @trusted { return (cast(Unqual!T)value).toString; }();
        else
            return value.toString;
    } else
        return T.stringof ~ "<cannot print>";
}


private string[] formatRange(T)(in string prefix, T value) {
    import std.conv: to;
    import std.range: ElementType;
    import std.algorithm: map, reduce, max;

    //some versions of `to` are @system
    auto defaultLines = () @trusted { return [prefix ~ value.to!string]; }();

    static if (!isInputRange!(ElementType!T))
        return defaultLines;
    else
    {
        import std.array: array;
        const maxElementSize = value.empty ? 0 : value.map!(a => a.array.length).reduce!max;
        const tooBigForOneLine = (value.array.length > 5 && maxElementSize > 5) || maxElementSize > 10;
        if (!tooBigForOneLine)
            return defaultLines;
        return [prefix ~ "["] ~
            value.map!(a => formatValue("              ", a).join("") ~ ",").array ~
            "          ]";
    }
}

private enum isObject(T) = is(T == class) || is(T == interface);

bool isEqual(V, E)(in auto ref V value, in auto ref E expected)
 if (!isObject!V &&
     (!isInputRange!V || !isInputRange!E) &&
     !isFloatingPoint!V && !isFloatingPoint!E &&
     is(typeof(value == expected) == bool))
{
    return value == expected;
}

bool isEqual(V, E)(in V value, in E expected)
 if (!isObject!V && (isFloatingPoint!V || isFloatingPoint!E) && is(typeof(value == expected) == bool))
{
    return value == expected;
}


bool isApproxEqual(V, E)(in V value, in E expected)
 if (!isObject!V && (isFloatingPoint!V || isFloatingPoint!E) && is(typeof(value == expected) == bool))
{
    import std.math;
    return approxEqual(value, expected);
}


void shouldApproxEqual(V, E)(in V value, in E expected, string file = __FILE__, size_t line = __LINE__)
 if (!isObject!V && (isFloatingPoint!V || isFloatingPoint!E) && is(typeof(value == expected) == bool))
{
    if (!isApproxEqual(value, expected))
    {
        const msg =
            formatValue("Expected approx: ", expected) ~
            formatValue("     Got       : ", value);
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe unittest {
    1.0.shouldApproxEqual(1.0001);
}


bool isEqual(V, E)(V value, E expected)
    if (!isObject!V && isInputRange!V && isInputRange!E && !isSomeString!V &&
        is(typeof(isEqual(value.front, expected.front))))
{

    while (!value.empty && !expected.empty) {
        if(!isEqual(value.front, expected.front)) return false;
        value.popFront;
        expected.popFront;
    }

    return value.empty && expected.empty;
}

bool isEqual(V, E)(V value, E expected)
    if (!isObject!V && isInputRange!V && isInputRange!E && isSomeString!V && isSomeString!E &&
        is(typeof(isEqual(value.front, expected.front))))
{
    if(value.length != expected.length) return false;
    // prevent auto-decoding
    foreach(i; 0 .. value.length)
        if(value[i] != expected[i]) return false;

    return true;
}


bool isEqual(V, E)(V value, E expected)
if (isObject!V && isObject!E)
{
    static assert(is(typeof(() { string s1 = value.toString; string s2 = expected.toString;})),
                  "Cannot compare instances of " ~ V.stringof ~
                  " or " ~ E.stringof ~ " unless toString is overridden for both");

    return (value is null && expected is null) ||
        (value !is null && expected !is null && value.tupleof == expected.tupleof);
}


/**
 * Verify that rng is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(R)(in auto ref R rng, in string file = __FILE__, in size_t line = __LINE__)
if (isInputRange!R)
{
    import std.conv: text;
    if (!rng.empty)
        fail(text("Range not empty: ", rng), file, line);
}

/**
 * Verify that rng is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(R)(auto ref shared(R) rng, in string file = __FILE__, in size_t line = __LINE__)
if (isInputRange!R)
{
    import std.conv: text;
    if (!rng.empty)
        fail(text("Range not empty: ", rng), file, line);
}


/**
 * Verify that aa is empty.
 * Throws: UnitTestException on failure.
 */
void shouldBeEmpty(T)(auto ref T aa, in string file = __FILE__, in size_t line = __LINE__)
if (isAssociativeArray!T)
{
    //keys is @system
    () @trusted{ if (!aa.keys.empty) fail("AA not empty", file, line); }();
}

///
@safe pure unittest
{
    int[] ints;
    string[] strings;
    string[string] aa;

    shouldBeEmpty(ints);
    shouldBeEmpty(strings);
    shouldBeEmpty(aa);

    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";
}


/**
 * Verify that rng is not empty.
 * Throws: UnitTestException on failure.
 */
void shouldNotBeEmpty(R)(R rng, in string file = __FILE__, in size_t line = __LINE__)
if (isInputRange!R)
{
    if (rng.empty)
        fail("Range empty", file, line);
}

/**
 * Verify that aa is not empty.
 * Throws: UnitTestException on failure.
 */
void shouldNotBeEmpty(T)(in auto ref T aa, in string file = __FILE__, in size_t line = __LINE__)
if (isAssociativeArray!T)
{
    //keys is @system
    () @trusted{ if (aa.keys.empty)
        fail("AA empty", file, line); }();
}

///
@safe pure unittest
{
    int[] ints;
    string[] strings;
    string[string] aa;

    ints ~= 1;
    strings ~= "foo";
    aa["foo"] = "bar";

    shouldNotBeEmpty(ints);
    shouldNotBeEmpty(strings);
    shouldNotBeEmpty(aa);
}

/**
 * Verify that t is greater than u.
 * Throws: UnitTestException on failure.
 */
void shouldBeGreaterThan(T, U)(in auto ref T t, in auto ref U u,
                               in string file = __FILE__, in size_t line = __LINE__)
{
    import std.conv: text;
    if (t <= u)
        fail(text(t, " is not > ", u), file, line);
}

///
@safe pure unittest
{
    shouldBeGreaterThan(7, 5);
}


/**
 * Verify that t is smaller than u.
 * Throws: UnitTestException on failure.
 */
void shouldBeSmallerThan(T, U)(in auto ref T t, in auto ref U u,
                               in string file = __FILE__, in size_t line = __LINE__)
{
    import std.conv: text;
    if (t >= u)
        fail(text(t, " is not < ", u), file, line);
}

///
@safe pure unittest
{
    shouldBeSmallerThan(5, 7);
}



/**
 * Verify that t and u represent the same set (ordering is not important).
 * Throws: UnitTestException on failure.
 */
void shouldBeSameSetAs(V, E)(auto ref V value, auto ref E expected, in string file = __FILE__, in size_t line = __LINE__)
if (isInputRange!V && isInputRange!E && is(typeof(value.front != expected.front) == bool))
{
    if (!isSameSet(value, expected))
    {
        const msg = formatValue("Expected: ", expected) ~
                    formatValue("     Got: ", value);
        throw new UnitTestException(msg, file, line);
    }
}

///
@safe pure unittest
{
    import std.range: iota;

    auto inOrder = iota(4);
    auto noOrder = [2, 3, 0, 1];
    auto oops = [2, 3, 4, 5];

    inOrder.shouldBeSameSetAs(noOrder);
    inOrder.shouldBeSameSetAs(oops).shouldThrow!UnitTestException;

    struct Struct
    {
        int i;
    }

    [Struct(1), Struct(4)].shouldBeSameSetAs([Struct(4), Struct(1)]);
}

private bool isSameSet(T, U)(auto ref T t, auto ref U u) {
    import std.algorithm: canFind;

    //sort makes the element types have to implement opCmp
    //instead, try one by one
    auto ta = t.array;
    auto ua = u.array;
    if (ta.length != ua.length) return false;
    foreach(element; ta)
    {
        if (!ua.canFind(element)) return false;
    }

    return true;
}

/**
 * Verify that value and expected do not represent the same set (ordering is not important).
 * Throws: UnitTestException on failure.
 */
void shouldNotBeSameSetAs(V, E)(auto ref V value, auto ref E expected, in string file = __FILE__, in size_t line = __LINE__)
if (isInputRange!V && isInputRange!E && is(typeof(value.front != expected.front) == bool))
{
    if (isSameSet(value, expected))
    {
        const msg = ["Value:",
                     formatValue("", value).join(""),
                     "is not expected to be equal to:",
                     formatValue("", expected).join("")
            ];
        throw new UnitTestException(msg, file, line);
    }
}


///
@safe pure unittest
{
    auto inOrder = iota(4);
    auto noOrder = [2, 3, 0, 1];
    auto oops = [2, 3, 4, 5];

    inOrder.shouldNotBeSameSetAs(oops);
    inOrder.shouldNotBeSameSetAs(noOrder).shouldThrow!UnitTestException;
}




/**
   If two strings represent the same JSON regardless of formatting
 */
void shouldBeSameJsonAs(in string actual,
                        in string expected,
                        in string file = __FILE__,
                        in size_t line = __LINE__)
    @trusted // not @safe pure due to parseJSON
{
    import std.json: parseJSON, JSONException;

    auto parse(in string str) {
        try
            return str.parseJSON;
        catch(JSONException ex)
            throw new UnitTestException("Error parsing JSON: " ~ ex.msg, file, line);
    }

    parse(actual).toPrettyString.shouldEqual(parse(expected).toPrettyString, file, line);
}

///
@safe unittest { // not pure because parseJSON isn't pure
    `{"foo": "bar"}`.shouldBeSameJsonAs(`{"foo": "bar"}`);
    `{"foo":    "bar"}`.shouldBeSameJsonAs(`{"foo":"bar"}`);
    `{"foo":"bar"}`.shouldBeSameJsonAs(`{"foo": "baz"}`).shouldThrow!UnitTestException;
    try
        `oops`.shouldBeSameJsonAs(`oops`);
    catch(Exception e)
        assert(e.msg == "Error parsing JSON: Unexpected character 'o'. (Line 1:1)");
}
