/**
 * Compiler implementation of the
 * $(LINK2 http://www.dlang.org, D programming language).
 *
 * Copyright:   Copyright (C) 1999-2018 by The D Language Foundation, All Rights Reserved
 * Authors:     $(LINK2 http://www.digitalmars.com, Walter Bright)
 * License:     $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/src/dmd/dversion.d, _dversion.d)
 * Documentation:  https://dlang.org/phobos/dmd_dversion.html
 * Coverage:    https://codecov.io/gh/dlang/dmd/src/master/src/dmd/dversion.d
 */

module dmd.dversion;

import dmd.arraytypes;
import dmd.cond;
import dmd.dmodule;
import dmd.dscope;
import dmd.dsymbol;
import dmd.dsymbolsem;
import dmd.globals;
import dmd.identifier;
import dmd.root.outbuffer;
import dmd.visitor;

/***********************************************************
 * DebugSymbol's happen for statements like:
 *      debug = identifier;
 *      debug = integer;
 */
extern (C++) final class DebugSymbol : Dsymbol
{
    uint level;

    extern (D) this(const ref Loc loc, Identifier ident)
    {
        super(ident);
        this.loc = loc;
    }

    extern (D) this(const ref Loc loc, uint level)
    {
        this.level = level;
        this.loc = loc;
    }

    override Dsymbol syntaxCopy(Dsymbol s)
    {
        assert(!s);
        auto ds = new DebugSymbol(loc, ident);
        ds.level = level;
        return ds;
    }

    override const(char)* toChars() const nothrow
    {
        if (ident)
            return ident.toChars();
        else
        {
            OutBuffer buf;
            buf.print(level);
            return buf.extractString();
        }
    }

    override void addMember(Scope* sc, ScopeDsymbol sds)
    {
        //printf("DebugSymbol::addMember('%s') %s\n", sds.toChars(), toChars());
        Module m = sds.isModule();
        // Do not add the member to the symbol table,
        // just make sure subsequent debug declarations work.
        if (ident)
        {
            if (!m)
            {
                error("declaration must be at module level");
                errors = true;
            }
            else
            {
                if (findCondition(m.debugidsNot, ident))
                {
                    error("defined after use");
                    errors = true;
                }
                if (!m.debugids)
                    m.debugids = new Identifiers();
                m.debugids.push(ident);
            }
        }
        else
        {
            if (!m)
            {
                error("level declaration must be at module level");
                errors = true;
            }
            else
                m.debuglevel = level;
        }
    }

    override const(char)* kind() const nothrow
    {
        return "debug";
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}

/***********************************************************
 * VersionSymbol's happen for statements like:
 *      version = identifier;
 *      version = integer;
 */
extern (C++) final class VersionSymbol : Dsymbol
{
    uint level;

    extern (D) this(const ref Loc loc, Identifier ident)
    {
        super(ident);
        this.loc = loc;
    }

    extern (D) this(const ref Loc loc, uint level)
    {
        this.level = level;
        this.loc = loc;
    }

    override Dsymbol syntaxCopy(Dsymbol s)
    {
        assert(!s);
        auto ds = ident ? new VersionSymbol(loc, ident)
                        : new VersionSymbol(loc, level);
        return ds;
    }

    override const(char)* toChars() nothrow
    {
        if (ident)
            return ident.toChars();
        else
        {
            OutBuffer buf;
            buf.print(level);
            return buf.extractString();
        }
    }

    override void addMember(Scope* sc, ScopeDsymbol sds)
    {
        //printf("VersionSymbol::addMember('%s') %s\n", sds.toChars(), toChars());
        Module m = sds.isModule();
        // Do not add the member to the symbol table,
        // just make sure subsequent debug declarations work.
        if (ident)
        {
            VersionCondition.checkReserved(loc, ident.toString());
            if (!m)
            {
                error("declaration must be at module level");
                errors = true;
            }
            else
            {
                if (findCondition(m.versionidsNot, ident))
                {
                    error("defined after use");
                    errors = true;
                }
                if (!m.versionids)
                    m.versionids = new Identifiers();
                m.versionids.push(ident);
            }
        }
        else
        {
            if (!m)
            {
                error("level declaration must be at module level");
                errors = true;
            }
            else
                m.versionlevel = level;
        }
    }

    override const(char)* kind() const nothrow
    {
        return "version";
    }

    override void accept(Visitor v)
    {
        v.visit(this);
    }
}
