package {{.Models}}

import (
    "encoding/gob"
    "errors"
    "fmt"
    "database/sql"
{{$ilen := len .Imports}}{{if gt $ilen 0}}{{range .Imports}}"{{.}}"{{end}}{{end}}

    "github.com/pychance/xorm"
    "github.com/pychance/xorm/configs"
    "github.com/pychance/xorm/db"
)

{{range .Tables}}
func init() {
    //{{Mapper .Name}}Model.Dao.EnableCache({{Mapper .Name}}Model)
    //{{Mapper .Name}}Model.Dao.DisableCache({{Mapper .Name}}Model)
	//gob: type not registered for interface
    gob.Register(&{{Mapper .Name}}{})
}

type {{Mapper .Name}} struct {
	Dao *db.XormDao `json:"-" xorm:"-"`
{{$table := .}}
{{range .ColumnsSeq}}{{$col := $table.GetColumn .}}	{{Mapper $col.Name}}	{{Type $col}} {{Tag $table $col}}
{{end}}
}

{{range .ColumnsSeq}}{{$col := $table.GetColumn .}}
func (m *{{Mapper $table.Name}}) Get{{Mapper $col.Name}}() (val {{Type $col}}) {
    if m == nil {
        return
    }
    return m.{{Mapper $col.Name}}
}
{{if $col.IsAutoIncrement}}
func (m *{{Mapper $table.Name}}) AutoIncrColName() string {
    return "{{$col.Name}}"
}

func (m *{{Mapper $table.Name}}) AutoIncrColValue() (val {{Type $col}}) {
    if m == nil {
        return
    }
    return m.{{Mapper $col.Name}}
}
{{end}}
{{end}}

func (m *{{Mapper .Name}}) String() string {
    return fmt.Sprintf("%#v", m)
}

func (m *{{Mapper .Name}}) TableName() string {
	return "{{.Name}}"
}

func (m *{{Mapper .Name}}) Save(t ...*{{Mapper .Name}}) (affected int64, err error) {
    if len(t) > 1 {
        return m.Dao.InsertMulti(t)
    } else {
        var i *{{Mapper .Name}}
        if len(t) == 0 {
            if m.Dao == nil {
                panic("dao not init")
            }
            i = m
        } else if len(t) == 1 {
            i = t[0]
        }
	    if i.AutoIncrColValue() > 0 {
		    return m.Dao.UpdateById(i)
    	} else {
            return m.Dao.Insert(i)
    	}
    }
}

func (m *{{Mapper .Name}}) Saves(t []*{{Mapper .Name}}) (affected int64, err error) {
    return m.Dao.InsertMulti(t)
}

func (m *{{Mapper .Name}}) Insert(t ...*{{Mapper .Name}}) (affected int64, err error) {
    if len(t) > 1 {
        return m.Dao.InsertMulti(t)
    } else {
        var i *{{Mapper .Name}}
        if len(t) == 0 {
            if m.Dao == nil {
                panic("dao not init")
            }
            i = m
        } else if len(t) == 1 {
            i = t[0]
        }
        return m.Dao.Insert(i)
    }
}

func (m *{{Mapper .Name}}) Update(params db.Cond,
	where db.Cond) (affected int64, err error) {
	return m.Dao.UpdateByWhere(m, params, where)
}

func (m *{{Mapper .Name}}) SearchOne(cond db.Cond) (t *{{Mapper .Name}}, err error) {
    if cond == nil {
        cond = db.Cond{}
    }
	cond["page"] = 1
	cond["pagesize"] = 1

	rs, err := m.Search(cond)
	if err != nil {
        return
    }
	if len(rs) > 0 {
		t = rs[0]
    }

	return
}

func (m *{{Mapper .Name}}) Search(cond db.Cond) (t []*{{Mapper .Name}}, err error) {
	err = m.Dao.Search(m, &t, cond)
	return
}

func (m *{{Mapper .Name}}) SearchAndCount(cond db.Cond) (t []*{{Mapper .Name}}, total int64, err error) {
	total, err = m.Dao.SearchAndCount(m, &t, cond)
	return
}

func (m *{{Mapper .Name}}) Rows(cond db.Cond) (rows *xorm.Rows, err error) {
	return m.Dao.Rows(m, cond)
}

func (m *{{Mapper .Name}}) Iterate(cond db.Cond, f xorm.IterFunc) (err error) {
	return m.Dao.Iterate(m, cond, f)
}

func (m *{{Mapper .Name}}) Count(cond db.Cond) (total int64, err error) {
	return m.Dao.Count(m, cond)
}

func (m *{{Mapper .Name}}) GetMulti(ids ...interface{}) (t []*{{Mapper .Name}}, err error) {
	err = m.Dao.GetMulti(m, &t, ids...)
	return
}

func (m *{{Mapper .Name}}) GetByIds(ids ...interface{}) (t []*{{Mapper .Name}}, err error) {
	return m.GetMulti(ids...)
}

func (m *{{Mapper .Name}}) GetById(id interface{}) (t *{{Mapper .Name}}, err error) {
	rs, err := m.GetMulti(id)
	if err != nil {
        return
    }
	if len(rs) > 0 {
		t = rs[0]
    }
	return
}

func (m *{{Mapper .Name}}) Replace(cond db.Cond) (int64, error) {
	defer m.Dao.ClearCache(m)
    return m.Dao.Replace(fmt.Sprintf("REPLACE `%s` SET ", m.TableName()), cond)
}

func (m *{{Mapper .Name}}) Exec(sqlState string, args ...interface{}) (sql.Result, error) {
	defer m.Dao.ClearCache(m)
	return m.Dao.Exec(sqlState, args...)
}

func (m *{{Mapper .Name}}) Query(args ...interface{}) ([]map[string][]byte, error) {
	return m.Dao.Query(args...)
}

func (m *{{Mapper .Name}}) QueryString(args ...interface{}) ([]map[string]string, error) {
	return m.Dao.QueryString(args...)
}

func (m *{{Mapper .Name}}) QueryInterface(args ...interface{}) ([]map[string]interface{}, error) {
	return m.Dao.QueryInterface(args...)
}

//以下用于事务，注意同个实例不能在多个goroutine同时使用
//使用完毕需要执行Close()，当Close的时候如果没有commit，会自动rollback
//参数只能是0-1个，可以是
//  configs.DbConfig    新生成dao
//  *db.XormDao         使用现有的dao
//  空                  使用默认的数据库配置
func New{{Mapper .Name}}IgnoreErr(c ...interface{}) (m *{{Mapper .Name}}) {
    m, _ = New{{Mapper .Name}}(c...)
    return
}

func New{{Mapper .Name}}(c ...interface{}) (m *{{Mapper .Name}}, err error) {
	m = &{{Mapper .Name}}{}
	var dbConfig configs.DbConfig
	if len(c) == 0 {
        dbConfig = hfw.Config.Db
	} else if len(c) == 1 {
		switch c[0].(type) {
		case configs.DbConfig:
			dbConfig = c[0].(configs.DbConfig)
		case *db.XormDao:
			m.Dao = c[0].(*db.XormDao)
            if m.Dao == nil {
                return nil, errors.New("nil dao")
            }
			return
        default:
            return nil, errors.New("error configs")
		}
	} else {
		return nil, errors.New("too many configs")
    }

	m.Dao, err = db.NewXormDao(hfw.Config, dbConfig)
	if err != nil {
		return nil, err
	}
	m.Dao.NewSession()

	return
}

func (m *{{Mapper .Name}}) Close() {
    m.Dao.Close()
}

func (m *{{Mapper .Name}}) Begin() error {
    return m.Dao.Begin()
}

func (m *{{Mapper .Name}}) Rollback() error {
    return m.Dao.Rollback()
}

func (m *{{Mapper .Name}}) Commit() error {
    return m.Dao.Commit()
}
{{end}}
