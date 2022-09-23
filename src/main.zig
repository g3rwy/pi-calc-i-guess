const std = @import("std");
const Ratio = std.math.big.Rational;
const BigInt = std.math.big.int.Managed;

// stdout should be actually Writer for stdout, but im just too lazy to check for name
fn printRatio(ratio: Ratio, prec: u32,alloc: std.mem.Allocator, stdout : anytype) !void {
    // std.debug.print("{}",.{ratio});
    var it = prec;
    if(!ratio.p.isPositive()){
        try stdout.print("-",.{});
    }
    try stdout.print("3.",.{});
    var comp = try BigInt.init(alloc);
    var @"3" = try BigInt.initSet(alloc,3);
    var @"10" = try BigInt.initSet(alloc,10);
    var junk  = try BigInt.init(alloc);

    defer {
        comp.deinit();
        junk.deinit();
        @"3".deinit();
        @"10".deinit();
    }
    
    try comp.mul(&ratio.q,&@"3");
    try comp.sub(&ratio.p,&comp);
    
    while(it != 0) : (it -= 1){
        if(comp.eqZero()) return;
        while( comp.order(ratio.q) == .lt ) { try comp.mul(&comp,&@"10"); if(comp.order(ratio.q) == .lt) try stdout.print("0",.{}); }
        var m = try BigInt.init(alloc);
        defer m.deinit();
        try m.divTrunc(&junk,&comp,&ratio.q); 
        
        try stdout.print("{}",.{m});

        try junk.mul(&m,&ratio.q);
        try comp.sub(&comp,&junk);
    }
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();
    
    const stdout = std.io.getStdOut().writer();

    const argv = try std.process.argsAlloc(alloc);
    _ = argv;
    defer std.process.argsFree(alloc, argv);
    errdefer std.process.argsFree(alloc, argv);

    var precision : u32 = 1;
    if(argv.len == 1) {
        try stdout.print("Giv some precision.\n",.{});
        return;
    }
    for(argv) |arg,i|{
        if(i == 1){
            precision = try std.fmt.parseInt(u32,arg,10);
        }
    }

    var p16       = try Ratio.init(alloc); try p16.setInt(1); var @"16" = try Ratio.init(alloc); try @"16".setInt(16);
    var pi        = try Ratio.init(alloc);

    // its funny using actual numbers for their variables
    var @"0"       = try Ratio.init(alloc);
    var @"1"       = try Ratio.init(alloc); try @"1".setInt(1);
    var @"2"       = try Ratio.init(alloc); try @"2".setInt(2);
    var @"4"       = try Ratio.init(alloc); try @"4".setInt(4);
    var @"5"       = try Ratio.init(alloc); try @"5".setInt(5);
    var @"6"       = try Ratio.init(alloc); try @"6".setInt(6);
    var @"8"       = try Ratio.init(alloc); try @"8".setInt(8);


    var a1 = try Ratio.init(alloc);    
    var a2 = try Ratio.init(alloc);
    var a3 = try Ratio.init(alloc);
    var a4 = try Ratio.init(alloc);
    var a5 = try Ratio.init(alloc);   
    var eightk = try Ratio.init(alloc);
    
    var k = try Ratio.init(alloc);


    defer {
        p16.deinit();
        pi.deinit();
        k.deinit();
        @"0".deinit(); @"1".deinit(); @"2".deinit(); @"4".deinit(); @"5".deinit(); @"6".deinit(); @"8".deinit(); @"16".deinit(); 
        a1.deinit();a2.deinit();a3.deinit();a4.deinit();a5.deinit();eightk.deinit();
    }
    
    var k_it = try k.p.to(u32);
    
    while(k_it <= precision) {
        
        //        a1           a2               a3              a4              a5       
        //pi += 1.0/p16 * ( 4.0/(8*k + 1) - 2.0/(8*k + 4) - 1.0/(8*k + 5) - 1.0/(8*k+6) );

        // FIXME might be way to optimize it
        // a1 = try Ratio.init(alloc);
        try a1.div(@"1" , p16);
        
        
        // var eightk = try Ratio.init(alloc); // its 8*k which repeats a lot
        try eightk.mul(@"8" , k);

        
        // var a2 = try Ratio.init(alloc);
        try a2.add(eightk, @"1");

        a2.q.swap(&a2.p);
        try a2.p.set(4); // divide by 4
            

        // var a3 = try Ratio.init(alloc);
        try a3.add(eightk, @"4");
        // try a3.div(@"2",a3);
        
        a3.q.swap(&a3.p);
        try a3.p.set(2); // divide by 2
        // try a3.reduce(); // reducing since we have doubles in there always

        // var a4 = try Ratio.init(alloc);
        try a4.add(eightk, @"5");
        // try a4.div(@"1",a4);

        a4.q.swap(&a4.p);
        try a4.p.set(1); // divide by 1


        // var a5 = try Ratio.init(alloc);
        try a5.add(eightk,@"6");
        // try a5.div(@"1",a5);

        a5.q.swap(&a5.p);
        try a5.p.set(1); // divide by 1 
                
        try a2.sub(a2,a3);
        try a2.sub(a2,a4);
        try a2.sub(a2,a5);

        try a1.mul(a1,a2);

        try pi.add(pi,a1);
        
        try p16.mul(p16,@"16");

        try k.p.addScalar(&k.p,1);
        k_it = try k.p.to(u32);
    }

    try printRatio(pi,precision,alloc,stdout);
}
